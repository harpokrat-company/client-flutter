package com.harpokrat.android;

import android.app.assist.AssistStructure;
import android.app.assist.AssistStructure.ViewNode;
import android.os.CancellationSignal;
import android.service.autofill.AutofillService;
import android.service.autofill.Dataset;
import android.service.autofill.FillCallback;
import android.service.autofill.FillContext;
import android.service.autofill.FillRequest;
import android.service.autofill.FillResponse;
import android.service.autofill.SaveCallback;
import android.service.autofill.SaveInfo;
import android.service.autofill.SaveRequest;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import android.util.ArrayMap;
import android.util.Log;
import android.view.autofill.AutofillId;
import android.view.autofill.AutofillValue;
import android.widget.RemoteViews;
import android.widget.Toast;

import com.harpokrat.android.R;
import java.util.Collection;
import java.util.stream.*;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.Map.Entry;

/**
 * A very basic {@link AutofillService} implementation that only shows dynamic-generated datasets
 * and don't persist the saved data.
 *
 * <p>The goal of this class is to provide a simple autofill service implementation that is easy
 * to understand and extend, but it should <strong>not</strong> be used as-is on real apps because
 * it lacks fundamental security requirements such as data partitioning and package verification
 * &mdashthese requirements are fullfilled by {@link MyAutofillService}.
 */
public final class HpkAutofillService extends AutofillService {

    private static final String TAG = "HpkAutofillService";

    private static List<Password> _passwords = new ArrayList<Password>();

    private static List<Password> _savedPasswords = new ArrayList<Password>();

    public static void addPassword(String login, String password, String domain) {
        Log.v(TAG, login + " " + password + " " + domain);
        Password pwd = new Password();
        pwd.domain = domain;
        pwd.login = login;
        pwd.password = password;
        if (!_passwords.contains(pwd))
            _passwords.add(pwd);
    }

    public static Password retrievePassword() {
        if (_savedPasswords.size() == 0)
            return null;
        Password p = _savedPasswords.get(0);
        _savedPasswords.remove(0);
        return p;
    }

    public static String canRetrievePassword() {
        Log.v(TAG, "In canRPassword");
        return (_savedPasswords.size() > 0) ? "true" : "false";
    }

    /**
     * Number of datasets sent on each request - we're simple, that value is hardcoded in our DNA!
     */
    private static final int NUMBER_DATASETS = 4;

    @Override
    public void onFillRequest(FillRequest request, CancellationSignal cancellationSignal,
                              FillCallback callback) {
        Log.d(TAG, "onFillRequest()");

        // Find autofillable fields
        AssistStructure structure = getLatestAssistStructure(request);
        List<Field> fields = getAutofillableFields(structure);
        Log.d(TAG, "autofillable fields:" + fields);

        if (fields.isEmpty()) {
            toast("No autofill hints found");
            callback.onSuccess(null);
            return;
        }

        // Create the base response
        FillResponse.Builder response = new FillResponse.Builder();

        // 1.Add the dynamic datasets
        String packageName = getApplicationContext().getPackageName();

        if (fields.size() < 1) {
            callback.onSuccess(null);
            return;
        }
        String appId = fields.get(0).packageId;
        List<Password> candidates = _passwords.stream()
                .filter(c -> c.domain.equals(appId))
                .collect(Collectors.toList());

        for (int i = 0; i < candidates.size(); i++) {
            Dataset.Builder dataset = new Dataset.Builder();
            for (Field field : fields) {
                String value = "";
                if (field.name.equals("password"))
                    value = candidates.get(i).password;
                else if (field.name.equals("email"))
                    value = candidates.get(i).password;
                else
                    continue;
                String displayValue = candidates.get(i).login;
                RemoteViews presentation = newDatasetPresentation(packageName, displayValue);
                dataset.setValue(field.id, AutofillValue.forText(value), presentation);
            }
            response.addDataset(dataset.build());
        }

        // 2.Add save info
        if (fields.size() == 2) {
            AutofillId[] requiredIds = new AutofillId[fields.size()];
            requiredIds[0] = fields.get(0).id;
            requiredIds[1] = fields.get(1).id;
            Log.d(TAG, "Reaquired id[0]: " + requiredIds[0]);
            Log.d(TAG, "Reaquired id[1]: " + requiredIds[1]);
            response.setSaveInfo(new SaveInfo.Builder(
                    SaveInfo.SAVE_DATA_TYPE_GENERIC,
                    requiredIds)
                    .build());
            Log.v(TAG, "SetSaveInfo done");
        }
        else {
            Log.v(TAG, "No enough fields found: " + fields.size());
        }
        // 3.Profit!
/*        if (candidates.size() == 0) {
            Log.v(TAG, "No candidate found for this view !!!!!!!!");
            return;
        }*/
        callback.onSuccess(response.build());
    }

    @Override
    public void onSaveRequest(SaveRequest request, SaveCallback callback) {
        Log.v(TAG, "onSaveRequest()");
        List<FillContext> context = request.getFillContexts();
        AssistStructure structure = context.get(context.size() - 1).getStructure();
        List<Field> fields = getAutofillableFields(structure);
        Password p = new Password();
        for (Field field : fields) {
            if (field.name.equals("password")) {
                p.password = field.value;
            } else if (field.name.equals("email")) {
                p.login = field.value;
            }
        }
        if (fields.size() > 0) {
            p.domain = fields.get(0).packageId;
            _savedPasswords.add(p);
            Log.v(TAG, "Password " + p.login + " & " + p.password + " -> " + p.domain + " Saved");
        }
        callback.onSuccess();
    }

    /**
     * Parses the {@link AssistStructure} representing the activity being autofilled, and returns a
     * map of autofillable fields (represented by their autofill ids) mapped by the hint associate
     * with them.
     *
     * <p>An autofillable field is a {@link ViewNode} whose {@link #getHint(ViewNode)} metho
     */
    @NonNull
    private List<Field> getAutofillableFields(@NonNull AssistStructure structure) {
        List<Field> fields = new ArrayList<>();
        int nodes = structure.getWindowNodeCount();
        for (int i = 0; i < nodes; i++) {
            ViewNode node = structure.getWindowNodeAt(i).getRootViewNode();
            addAutofillableFields(fields, node);
        }
        return fields;
    }

    /**
     * Adds any autofillable view from the {@link ViewNode} and its descendants to the map.
     */
    private void addAutofillableFields(@NonNull List<Field> fields,
                                       @NonNull ViewNode node) {
        String[] hints = node.getAutofillHints();
        if (hints != null) {
            // We're simple, we only care about the first hint
            for (String hint : hints)
                Log.v(TAG, hint);
            String hint = hints[0].toLowerCase();

            if (hint != null) {
                AutofillId id = node.getAutofillId();
                Log.v(TAG, "Setting hint '" + hint + "' on " + id);
                AutofillValue afv = node.getAutofillValue();
                if (afv != null && afv.isText())
                    fields.add(new Field(hint, node.getIdPackage(), id, afv.getTextValue().toString()));
                else
                    fields.add(new Field(hint, node.getIdPackage(), id));
            }
        }
/*        if (!node.getVisibility()) {
            Log.v(TAG, "visibility False detected");
            fields.put("password", node.getAutofillId());
        }*/
        String hint = node.getHint();
        if (hint != null) {
            hint = hint.toLowerCase();
            if (hint.equals("email") || hint.equals("password")) {
                Log.v(TAG, node.getIdPackage());
                Log.v(TAG, "visibility False detected");
                AutofillId id = node.getAutofillId();
                AutofillValue afv = node.getAutofillValue();
                if (afv != null && afv.isText())
                    fields.add(new Field(hint, node.getIdPackage(), id, afv.getTextValue().toString()));
                else
                    fields.add(new Field(hint, node.getIdPackage(), id));
            }
        }
        Log.v(TAG, hint + " detected");
        int childrenSize = node.getChildCount();
        for (int i = 0; i < childrenSize; i++) {
            addAutofillableFields(fields, node.getChildAt(i));
        }
    }

    /**
     * Helper method to get the {@link AssistStructure} associated with the latest request
     * in an autofill context.
     */
    @NonNull
    static AssistStructure getLatestAssistStructure(@NonNull FillRequest request) {
        List<FillContext> fillContexts = request.getFillContexts();
        return fillContexts.get(fillContexts.size() - 1).getStructure();
    }

    /**
     * Helper method to create a dataset presentation with the given text.
     */
    @NonNull
    static RemoteViews newDatasetPresentation(@NonNull String packageName,
                                              @NonNull CharSequence text) {
        RemoteViews presentation =
                new RemoteViews(packageName, R.layout.multidataset_service_list_item);
        presentation.setTextViewText(R.id.text, text);
        presentation.setImageViewResource(R.id.icon, R.mipmap.ic_launcher);
        return presentation;
    }

    /**
     * Displays a toast with the given message.
     */
    private void toast(@NonNull CharSequence message) {
        Toast.makeText(getApplicationContext(), message, Toast.LENGTH_LONG).show();
    }
}

class Password {
    public String login;
    public String domain;
    public String password;

    Map<String, String> getAsMap() {
        Map<String, String> r = new ArrayMap<>();
        r.put("login", login);
        r.put("password", password);
        r.put("domain", domain);
        return r;
    }
}

class Field {
    public String name;
    public String packageId;
    public String value;
    public AutofillId id;


    String getNameFromHint(String hint) {
        if (hint.equals("email"))
            return "email";
        if (hint.equals("username"))
            return "email";
        if (hint.equals("user"))
            return "email";
        if (hint.equals("pseudo"))
            return "email";
        if (hint.equals("login"))
            return "email";
        if (hint.equals("password"))
            return "password";
        return hint;
    }

    Field(String name, String packageId, AutofillId id, String value) {
        this.name = getNameFromHint(name);
        this.value = value;
        this.packageId = packageId;
        this.id = id;
    }

    Field(String name, String packageId, AutofillId id) {
        this.name = name;
        this.value = "";
        this.packageId = packageId;
        this.id = id;
    }
}
package com.harpokrat.android;
/*
import android.annotation.SuppressLint;
import android.app.assist.AssistStructure;
import android.os.Build;
import android.os.CancellationSignal;
import android.service.autofill.AutofillService;
import android.service.autofill.Dataset;
import android.service.autofill.FillCallback;
import android.service.autofill.FillContext;
import android.service.autofill.FillRequest;
import android.service.autofill.FillResponse;
import android.service.autofill.SaveCallback;
import android.service.autofill.SaveRequest;
import android.view.View;
import android.view.autofill.AutofillId;
import android.view.autofill.AutofillValue;
import android.widget.RemoteViews;

import java.util.Arrays;
import java.util.Enumeration;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

@SuppressLint("Registered")
@RequiresApi(api = Build.VERSION_CODES.O)
public class HpkAutofillService extends AutofillService {
    @Override
    public void onFillRequest(@NonNull @android.support.annotation.NonNull FillRequest request, @NonNull @android.support.annotation.NonNull CancellationSignal cancellationSignal, @NonNull @android.support.annotation.NonNull FillCallback callback) {
        // Get the structure from the request
        List<FillContext> context = request.getFillContexts();
        AssistStructure structure = context.get(context.size() - 1).getStructure();

        // Traverse the structure looking for nodes to fill out.
        ParsedStructure parsedStructure = parseStructure(structure);

        // Build the presentation of the datasets
        RemoteViews usernamePresentation = new RemoteViews(getPackageName(), android.R.layout.simple_list_item_1);
        usernamePresentation.setTextViewText(android.R.id.text1, "my username");
        RemoteViews passwordPresentation = new RemoteViews(getPackageName(), android.R.layout.simple_list_item_1);
        passwordPresentation.setTextViewText(android.R.id.text1, "Password for my username");

        // Add a dataset to the response
        FillResponse fillResponse = new FillResponse.Builder()
                .addDataset(new Dataset.Builder()
                        .setValue(parsedStructure.getUsernameId(),
                                AutofillValue.forText(userData.username), usernamePresentation)
                        .setValue(parsedStructure.getPasswordId(),
                                AutofillValue.forText(userData.password), passwordPresentation)
                        .build())
                .build();

        // If there are no errors, call onSuccess() and pass the response
        callback.onSuccess(fillResponse);
    }

    @Override
    public void onSaveRequest(@NonNull @android.support.annotation.NonNull SaveRequest request, @NonNull @android.support.annotation.NonNull SaveCallback callback) {

    }

    public AutofillId getNodeId(AssistStructure.ViewNode viewNode, String hint) {

        if(viewNode.getAutofillHints() != null && viewNode.getAutofillHints().length > 0) {
            // If the client app provides autofill hints, you can obtain them using:
            List<String> hints = Arrays.asList(viewNode.getAutofillHints());
            if (hints.contains(hint)) {
                return viewNode.getAutofillId();
            }
        }
        for (int i = 0; i < viewNode.getChildCount(); i++) {
            AssistStructure.ViewNode childNode = viewNode.getChildAt(i);
            AutofillId id = getNodeId(childNode, hint);
            if (id != null)
                return id;
        }
        return null;
    }

    private ParsedStructure parseStructure(AssistStructure structure) {
        int nodes = structure.getWindowNodeCount();
        AutofillId user_id = null;
        AutofillId password_id = null;

        for (int i = 0; i < nodes; i++) {
            AssistStructure.WindowNode windowNode = structure.getWindowNodeAt(i);
            AssistStructure.ViewNode viewNode = windowNode.getRootViewNode();
            if (user_id == null)
                user_id = getNodeId(viewNode, View.AUTOFILL_HINT_USERNAME);
            if (password_id == null)
                password_id =  getNodeId(viewNode, View.AUTOFILL_HINT_PASSWORD);
        }
        return new ParsedStructure(user_id, password_id);
    }
}

class ParsedStructure {
    private AutofillId usernameId;
    private AutofillId passwordId;

    ParsedStructure(AutofillId usernameId, AutofillId passwordId) {
        this.usernameId = usernameId;
        this.passwordId = passwordId;
    }

    public AutofillId getUsernameId() {
        return usernameId;
    }

    public AutofillId getPasswordId() {
        return passwordId;
    }
}

class UserData {
    String username;
    String password;

    UserData(String username, String password) {
        this.username = username;
        this.password = password;
    }
}

 */
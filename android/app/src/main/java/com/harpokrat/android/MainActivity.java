package com.harpokrat.android;

import android.os.Bundle;
import androidx.annotation.NonNull;

import android.util.Log;

import com.google.android.gms.safetynet.SafetyNet;
import com.google.android.gms.safetynet.SafetyNetApi;
import com.google.android.gms.tasks.*;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodChannel;

import com.harpokrat.android.HpkAutofillService;


public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "com.harpokrat.android/autofill";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            Log.v("plop", "gvuvyv");
                            if (call.method.equals("isSupported")) {
                                result.success(true);
                            } else if (call.method.equals("verify")) {
                                String siteKey = call.argument("key");

                                SafetyNet.getClient(this).verifyWithRecaptcha(siteKey)
                                        .addOnSuccessListener(new OnSuccessListener<SafetyNetApi.RecaptchaTokenResponse>() {
                                            @Override
                                            public void onSuccess(SafetyNetApi.RecaptchaTokenResponse response) {
                                                result.success(response.getTokenResult());
                                            }
                                        })
                                        .addOnFailureListener(new OnFailureListener() {
                                            @Override
                                            public void onFailure(@NonNull Exception e) {
                                                e.printStackTrace();
                                                result.error("f_grecaptcha",
                                                        "Verification using reCaptcha has failed", null);
                                            }
                                        });
                            }

                            else if (call.method.equals("givePassword")) {
                                String password = call.argument("password");
                                String login = call.argument("login");
                                String domain = call.argument("domain");
                                HpkAutofillService.addPassword(login, password, domain);
                                result.success(true);
                            } else if (call.method.equals("retrievePasswords")) {
                                String attribute = call.argument("attribute");
                                if (attribute.equals("password")) {
                                    Password p = HpkAutofillService.retrievePassword(false);
                                    result.success(p.password);
                                } else if (attribute.equals("login")) {
                                    Password p = HpkAutofillService.retrievePassword(false);
                                    result.success(p.login);
                                } else if (attribute.equals("domain")) {
                                    Password p = HpkAutofillService.retrievePassword(false);
                                    result.success(p.domain);
                                } else if (attribute.equals("next")) {
                                    HpkAutofillService.retrievePassword(true);
                                    result.success("empty");
                                }
                             }
                            // Note: this method is invoked on the main thread.
                            // TODO
                        }
                );
    }

}

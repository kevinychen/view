package com.kyc.view;

import org.glassfish.jersey.media.multipart.MultiPartFeature;
import org.opencv.core.Core;

import io.dropwizard.Application;
import io.dropwizard.Configuration;
import io.dropwizard.setup.Environment;
import nu.pattern.OpenCV;

public class ViewServer extends Application<Configuration> {

    @Override
    public void run(Configuration configuration, Environment environment) throws Exception {
        PieceParser pieceParser = new PieceParser();

        environment.jersey().register(new MultiPartFeature());
        environment.jersey().register(new ViewResource(pieceParser));
    }

    public static void main(String[] args) throws Exception {
        OpenCV.loadShared();
        System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
        new ViewServer().run("server");
    }
}

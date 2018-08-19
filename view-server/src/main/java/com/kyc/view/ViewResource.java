
package com.kyc.view;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.UUID;

import javax.imageio.ImageIO;
import javax.ws.rs.Consumes;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.glassfish.jersey.media.multipart.FormDataParam;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.coobird.thumbnailator.Thumbnails;

@Path("/")
public class ViewResource {

    private static final Logger log = LoggerFactory.getLogger(ViewServer.class);

    public static final File UPLOAD_DIR = new File("./data");

    private final PieceParser pieceParser;

    public ViewResource(PieceParser pieceParser) {
        this.pieceParser = pieceParser;
    }

    @POST
    @Path("upload")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.APPLICATION_OCTET_STREAM)
    public Response uploadFile(
            @FormDataParam("file") final InputStream fileInputStream) throws IOException {
        File uploadFile = new File(UPLOAD_DIR, String.format("upload-%s.png", UUID.randomUUID()));
        log.info("Uploading file {}", uploadFile);

        BufferedImage image = Thumbnails.of(fileInputStream).scale(1).asBufferedImage();
        List<Side> sides = pieceParser.parse(image);
        pieceParser.annotateImage(image, sides);
        if (!ImageIO.write(image, "png", uploadFile)) {
            throw new RuntimeException("Error writing file");
        }
        return Response.ok(uploadFile).build();
    }
}

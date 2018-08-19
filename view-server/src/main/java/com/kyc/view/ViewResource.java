
package com.kyc.view;

import java.awt.Color;
import java.awt.Graphics;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import javax.imageio.ImageIO;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.glassfish.jersey.media.multipart.FormDataParam;
import org.opencv.core.Point;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;

import net.coobird.thumbnailator.Thumbnails;

@Path("/")
public class ViewResource {

    private static final Logger log = LoggerFactory.getLogger(ViewServer.class);
    private static final ObjectMapper mapper = new ObjectMapper(new YAMLFactory());

    public static final File PIECES_DIR = new File("./data/pieces");
    public static final File SAVED_PIECES_DIR = new File("./data/saved");

    private final PieceParser pieceParser;
    private final AtomicInteger currentPieceId = new AtomicInteger();

    public ViewResource(PieceParser pieceParser) {
        this.pieceParser = pieceParser;

        PIECES_DIR.mkdirs();
        SAVED_PIECES_DIR.mkdirs();

        for (String uploadedFiles : PIECES_DIR.list()) {
            int newPieceId = Integer.parseInt(uploadedFiles.replaceAll("[^0-9]", ""));
            currentPieceId.updateAndGet(pieceId -> Math.max(pieceId, newPieceId + 1));
        }
        log.info("Initialized current piece id to {}", currentPieceId);
    }

    @POST
    @Path("piece")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.APPLICATION_JSON)
    public AddPieceResponse addPiece(
            @FormDataParam("file") final InputStream fileInputStream) throws IOException {
        String pieceId = currentPieceId.getAndIncrement() + "";
        log.info("Parsing piece {}", pieceId);

        BufferedImage image = Thumbnails.of(fileInputStream).scale(1).asBufferedImage();
        List<Side> sides = pieceParser.parse(image);

        if (!ImageIO.write(image, "png", getPieceFile(pieceId))) {
            throw new RuntimeException("Error writing file");
        }
        mapper.writeValue(getParsedPieceFile(pieceId), new Piece(sides));
        return new AddPieceResponse(pieceId);
    }

    @GET
    @Path("piece/{pieceId}/image")
    @Produces(MediaType.APPLICATION_OCTET_STREAM)
    public Response getPieceImage(@PathParam("pieceId") String pieceId) throws IOException {
        BufferedImage image = ImageIO.read(getPieceFile(pieceId));
        List<Side> sides = mapper.readValue(getParsedPieceFile(pieceId), Piece.class).sides;

        Color[] colors = { Color.red, Color.yellow, Color.green, Color.blue };
        Graphics g = image.getGraphics();
        for (int i = 0; i < colors.length; i++) {
            g.setColor(colors[i]);
            for (Point p : sides.get(i).points)
                g.fillOval((int) p.x - 2, (int) p.y - 2, 5, 5);
        }

        ByteArrayOutputStream output = new ByteArrayOutputStream();
        if (!ImageIO.write(image, "png", output)) {
            throw new RuntimeException("Error writing response");
        }
        return Response.ok(output.toByteArray()).build();
    }

    private static File getPieceFile(String pieceId) {
        return new File(PIECES_DIR, String.format("piece-%s.png", pieceId));
    }

    private static File getParsedPieceFile(String pieceId) {
        return new File(PIECES_DIR, String.format("piece-%s.yml", pieceId));
    }
}

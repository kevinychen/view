package com.kyc.view;

import java.awt.Color;
import java.awt.Point;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.imageio.ImageIO;

import org.opencv.core.Core;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;

import nu.pattern.OpenCV;

public class BulkPieceParser {

    private static final ObjectMapper mapper = new ObjectMapper(new YAMLFactory());

    public void bulkParse(String name) throws IOException {
        BufferedImage image = ImageIO.read(new File(PieceTester.REMAINING_PIECES_DIR, name + ".png"));

        boolean[][] used = new boolean[image.getHeight()][image.getWidth()];
        PieceParser parser = new PieceParser();
        for (int x = 0; x < image.getWidth(); x++)
            for (int y = 0; y < image.getHeight(); y++)
                if (isBlue(image.getRGB(x, y)) && !used[y][x]) {
                    List<Point> ff = new ArrayList<>();
                    ff.add(new Point(x, y));
                    int minX = Integer.MAX_VALUE;
                    int minY = Integer.MAX_VALUE;
                    int maxX = Integer.MIN_VALUE;
                    int maxY = Integer.MIN_VALUE;
                    int size = 0;
                    while (!ff.isEmpty()) {
                        Point p = ff.remove(ff.size() - 1);
                        if (p.x >= 0 && p.x < image.getWidth() && p.y >= 0 && p.y < image.getHeight() && isBlue(image.getRGB(p.x, p.y))
                                && !used[p.y][p.x]) {
                            used[p.y][p.x] = true;
                            size++;
                            for (int dx = -2; dx <= 2; dx++)
                                for (int dy = -2; dy <= 2; dy++)
                                    ff.add(new Point(p.x + dx, p.y + dy));
                            if (p.x < minX)
                                minX = p.x;
                            if (p.y < minY)
                                minY = p.y;
                            if (p.x > maxX)
                                maxX = p.x;
                            if (p.y > maxY)
                                maxY = p.y;
                        }
                    }
                    if (size > 1000 && minX >= 5 && minY >= 5 && maxX < image.getWidth() - 5 && maxY < image.getHeight() - 5) {
                        try {
                            Piece piece = new Piece(parser.parse(image.getSubimage(minX - 5, minY - 5, maxX - minX + 10, maxY - minY + 10)));
                            mapper.writeValue(new File(PieceTester.REMAINING_PIECES_DIR,
                                String.format("%s-%s-%s.yml", name, (minX + maxX) / 2, (minY + maxY) / 2)), piece);
                        } catch (RuntimeException e) {
                            System.out.println("FAILED!");
                        }
                    }
                }
    }

    private boolean isBlue(int rgb) {
        Color color = new Color(rgb);
        float[] hsb = Color.RGBtoHSB(color.getRed(), color.getGreen(), color.getBlue(), null);
        return hsb[0] >= 0.2 && hsb[0] < 0.9;
    }

    public static void main(String[] args) throws IOException {
        OpenCV.loadShared();
        System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
        new BulkPieceParser().bulkParse("bulk1");
    }
}

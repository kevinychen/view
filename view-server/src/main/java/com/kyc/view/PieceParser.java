package com.kyc.view;

import java.awt.Color;
import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.Point;
import org.opencv.imgproc.Imgproc;

public class PieceParser {

    public List<Side> parse(BufferedImage image) {
        Mat mat = toGrayscaleMat(image);

        List<MatOfPoint> contours = new ArrayList<>();
        Imgproc.findContours(mat, contours, mat, Imgproc.RETR_LIST, Imgproc.CHAIN_APPROX_NONE);
        Point[] contour = getLongestContour(contours);

        double[] orientations = getOrientations(contour);
        Point center = center(contour);

        /*
         * Compute the 4 puzzle corners of the jigsaw piece.
         * k=0: SOUTHWEST (angle = 3pi/4)
         * k=1: NORTHWEST (angle = 5pi/4)
         * k=2: NORTHEAST (angle = 7pi/4)
         * k=3: SOUTHEAST (angle = 9pi/4 = pi/4)
         */
        int[] corners = new int[4];
        double[] gaussian = gaussian(contour.length, 256);
        for (int k = 0; k < 4; k++) {
            int min_ssd_i = -1;
            double min_ssd = Double.MAX_VALUE;
            for (int i = 0; i < contour.length; i++) {
                double expectedDirectionFromCenter = k * Math.PI / 2 + 3 * Math.PI / 4;
                if (!isCloseToExpectedDirection(contour[i], center, expectedDirectionFromCenter))
                    continue;

                double leftExpectedOrientation = k * Math.PI / 2;
                double rightExpectedOrientation = ((k + 1) % 4) * Math.PI / 2;
                double ssd = similarityToPureCorner(leftExpectedOrientation, rightExpectedOrientation, orientations, i, gaussian);
                if (ssd < min_ssd) {
                    min_ssd_i = i;
                    min_ssd = ssd;
                }
            }
            corners[k] = min_ssd_i;
        }

        /**
         * Compute the 4 sides of the contours.
         * k=0: west (SOUTHWEST to NORTHWEST)
         * k=1: north (NORTHWEST to NORTHEAST)
         * k=2: east (NORTHEAST to SOUTHEAST)
         * k=3: south (SOUTHEAST to SOUTHWEST)
         */
        List<Side> sides = new ArrayList<>();
        for (int k = 0; k < 4; k++)
            sides.add(new Side(subsequence(contour, corners[(k + 1) % 4], corners[k])));
        return sides;
    }

    private Mat toGrayscaleMat(BufferedImage image) {
        Mat mat = new Mat(image.getHeight(), image.getWidth(), CvType.CV_8UC1);
        for (int x = 0; x < image.getWidth(); x++)
            for (int y = 0; y < image.getHeight(); y++)
                mat.put(y, x, isBlue(image.getRGB(x, y)) ? 1 : 0);
        return mat;
    }

    private boolean isBlue(int rgb) {
        Color color = new Color(rgb);
        float[] hsb = Color.RGBtoHSB(color.getRed(), color.getGreen(), color.getBlue(), null);
        return hsb[0] >= 0.2 && hsb[0] < 0.9;
    }

    private Point[] getLongestContour(List<MatOfPoint> contours) {
        return contours.stream()
                .max(Comparator.comparingInt(c -> c.toArray().length))
                .orElseThrow(() -> new RuntimeException("No contour found"))
                .toArray();
    }

    private double[] getOrientations(Point[] contour) {
        int D = 5;
        double[] orientations = new double[contour.length];
        for (int i = 0; i < contour.length; i++) {
            Point prev = contour[(i + contour.length - D) % contour.length];
            Point next = contour[(i + D) % contour.length];
            orientations[i] = Math.atan2(next.y - prev.y, next.x - prev.x);
        }
        return orientations;
    }

    private Point center(Point[] points) {
        int sumX = 0, sumY = 0;
        for (Point p : points) {
            sumX += p.x;
            sumY += p.y;
        }
        return new Point(sumX / points.length, sumY / points.length);
    }

    private boolean isCloseToExpectedDirection(Point point, Point center, double expectedDirectionFromCenter) {
        double direction = Math.atan2(point.y - center.y, point.x - center.x);
        return Math.abs(getClosestEquivalentAngle(direction, expectedDirectionFromCenter) - expectedDirectionFromCenter) < Math.PI / 16;
    }

    private double similarityToPureCorner(double leftExpectedOrientation, double rightExpectedOrientation, double[] orientations,
            int middle, double[] gaussian) {
        double ssd = 0;
        for (int i = 0; i < orientations.length; i++) {
            double expectedOrientation = i < orientations.length - i ? leftExpectedOrientation : rightExpectedOrientation;
            double orientation = orientations[(middle + i) % orientations.length];
            ssd += gaussian[Math.min(i, orientations.length - i)]
                    * Math.pow(getClosestEquivalentAngle(orientation, expectedOrientation) - expectedOrientation, 2);
        }
        return ssd;
    }

    private List<Point> subsequence(Point[] points, int start, int end) {
        List<Point> subseq = new ArrayList<>();
        for (int i = start; i != end; i = (i + 1) % points.length)
            subseq.add(points[i]);
        return subseq;
    }

    private double getClosestEquivalentAngle(double angle, double target) {
        while (angle > target + Math.PI)
            angle -= 2 * Math.PI;
        while (angle < target - Math.PI)
            angle += 2 * Math.PI;
        return angle;
    }

    private double[] gaussian(int size, double sigma) {
        double[] gaussian = new double[size];
        for (int x = 0; x < size; x++)
            gaussian[x] = Math.exp(-Math.pow(x + 0.5, 2) / (2 * sigma * sigma)) / Math.sqrt(2 * Math.PI * sigma * sigma);
        return gaussian;
    }
}

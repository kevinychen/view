package com.kyc.view;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

import org.opencv.core.Point;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.google.common.collect.ImmutableList;
import com.google.common.io.Files;

import lombok.Data;

public class PieceTester {

    private static final ObjectMapper mapper = new ObjectMapper(new YAMLFactory());
    private static final int[] drow = {0, -1, 0, 1};
    private static final int[] dcol = {-1, 0, 1, 0};

    public static final File SAVED_PIECES_DIR = new File("./data/saved");
    public static final File GRID_FILE = new File("./data/grid.txt");
    public static final File REMAINING_PIECES_DIR = new File("./data/remaining");

    private final int height;
    private final int width;
    private final boolean[][] used;
    private final OrientedPiece[][] pieces;

    public PieceTester() throws IOException {
        SAVED_PIECES_DIR.mkdirs();

        List<String> gridLines = Files.readLines(GRID_FILE, StandardCharsets.UTF_8);
        height = gridLines.size();
        width = gridLines.get(0).length();

        used = new boolean[height][width];
        for (int row = 0; row < used.length; row++)
            for (int col = 0; col < used[row].length; col++)
                used[row][col] = gridLines.get(row).charAt(col) == '*';

        pieces = new OrientedPiece[height][width];
        for (File pieceFile : SAVED_PIECES_DIR.listFiles(file -> file.getName().endsWith(".yml")))
            addPiece(mapper.readValue(pieceFile, Piece.class));
    }

    public void save(String pieceId, Piece piece) throws IOException {
        mapper.writeValue(getSavedPieceFile(pieceId), piece);
        addPiece(piece);
    }

    public List<PieceSuggestion> findSuggestions(int row, int col) throws IOException {
        List<PieceSuggestion> suggestions = new ArrayList<>();
        for (File pieceFile : REMAINING_PIECES_DIR.listFiles(file -> file.getName().endsWith(".yml"))) {
            Piece piece = mapper.readValue(pieceFile, Piece.class);
            for (int dir = 0; dir < 4; dir++) {
                piece.dir = dir;
                double score = score(row, col, orient(piece));
                suggestions.add(new PieceSuggestion(pieceFile.getName(), score));
            }
        }
        Collections.sort(suggestions, Comparator.comparingDouble(suggestion -> -suggestion.score));
        while (suggestions.size() > 10)
            suggestions = suggestions.subList(0, 10);
        return suggestions;
    }

    public List<LocationSuggestion> findSuggestions(Piece piece) throws IOException {
        Integer originalDir = piece.dir;
        List<LocationSuggestion> suggestions = new ArrayList<>();
        for (int row = 0; row < height; row++)
            for (int col = 0; col < width; col++) {
                if (used[row][col])
                    continue;
                for (int dir = 0; dir < 4; dir++) {
                    piece.dir = dir;
                    double score = score(row, col, orient(piece));
                    suggestions.add(new LocationSuggestion(row, col, dir, score));
                }
            }
        piece.dir = originalDir;
        Collections.sort(suggestions, Comparator.comparingDouble(suggestion -> -suggestion.score));
        while (suggestions.size() > 5)
            suggestions = suggestions.subList(0, 5);
        return suggestions;
    }

    private void addPiece(Piece piece) {
        if (piece.row != null && piece.col != null)
            pieces[piece.row][piece.col] = orient(piece);
    }

    private double score(int row, int col, OrientedPiece piece) {
        double minScore = Double.MAX_VALUE;
        for (int i = 0; i < 4; i++) {
            int nrow = row + drow[i];
            int ncol = col + dcol[i];
            if (nrow < 0 || nrow >= height || ncol < 0 || ncol >= width || pieces[nrow][ncol] == null)
                continue;
            List<Point> points = normalize(piece.sides.get(i).points);
            List<Point> neighboringPoints = normalize(reverse(pieces[nrow][ncol].sides.get((i + 2) % 4)).points);
            double score = 1.0 / difference(points, neighboringPoints);
            if (score < minScore)
                minScore = score;
        }
        return minScore;
    }

    private static Side reverse(Side side) {
        List<Point> reversed = new ArrayList<>(side.points);
        Collections.reverse(reversed);
        return new Side(reversed);
    }

    private static List<Point> normalize(List<Point> points) {
        Point first = points.get(0);
        Point last = points.get(points.size() - 1);
        double baseX = last.x - first.x, baseY = last.y - first.y;
        double scale = Math.hypot(baseX, baseY);
        double angle = Math.atan2(baseY, baseX);
        return points.stream().map(p -> {
            double x = p.x - first.x, y = p.y - first.y;
            return new Point((Math.cos(-angle) * x - Math.sin(-angle) * y) / scale, (Math.sin(-angle) * x + Math.cos(-angle) * y) / scale);
        }).collect(Collectors.toList());
    }

    private static OrientedPiece orient(Piece piece) {
        List<Side> sides = new ArrayList<>(piece.sides);
        if (piece.flip != null && piece.flip) {
            sides = ImmutableList.of(
                reverse(flip(sides.get(2))),
                reverse(flip(sides.get(1))),
                reverse(flip(sides.get(0))),
                reverse(flip(sides.get(3))));
        }
        if (piece.dir != null)
            sides = ImmutableList.<Side> builder()
                .addAll(sides.subList(piece.dir, 4))
                .addAll(sides.subList(0, piece.dir))
                .build();
        return new OrientedPiece(sides);
    }

    private static Side flip(Side side) {
        return new Side(side.points.stream()
            .map(p -> new Point(-p.x, p.y))
            .collect(Collectors.toList()));
    }

    private static double difference(List<Point> side1, List<Point> side2) {
        double difference1 = 0;
        for (Point p : side1)
            difference1 += closestDist2(side2, p);
        double difference2 = 0;
        for (Point p : side2)
            difference2 += closestDist2(side1, p);
        return difference1 / side1.size() + difference2 / side2.size();
    }

    private static double closestDist2(List<Point> points, Point target) {
        double closestDist2 = Double.MAX_VALUE;
        for (Point p : points) {
            double dx = p.x - target.x, dy = p.y - target.y;
            double dist2 = dx * dx + dy * dy;
            if (dist2 < closestDist2)
                closestDist2 = dist2;
        }
        return closestDist2;
    }

    private static File getSavedPieceFile(String pieceId) {
        return new File(SAVED_PIECES_DIR, String.format("piece-%s.yml", pieceId));
    }

    @Data
    static class OrientedPiece {
        final List<Side> sides;
    }
}

package com.kyc.view;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonInclude.Include;

import lombok.Data;

@Data
@JsonInclude(Include.NON_NULL)
public class Piece {
    public Integer row;
    public Integer col;
    public Integer dir;
    public Boolean flip;
    /**
     * 4 sides; if dir is 0, (left, top, right, bottom); otherwise, shifted by the dir, e.g. if
     * dir=3, then left is index 3.
     */
    public final List<Side> sides;
}

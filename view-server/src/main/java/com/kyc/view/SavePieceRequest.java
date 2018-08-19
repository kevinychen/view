package com.kyc.view;

import lombok.Data;

@Data
public class SavePieceRequest {
    Integer row;
    Integer col;
    Integer dir;
    boolean flip = false;
}

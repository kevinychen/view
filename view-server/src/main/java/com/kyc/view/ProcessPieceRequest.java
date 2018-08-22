package com.kyc.view;

import lombok.Data;

@Data
public class ProcessPieceRequest {
    Integer row;
    Integer col;
    Integer dir;
    boolean flip = false;
}

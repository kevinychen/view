package com.kyc.view;

import java.util.List;

import lombok.Data;

@Data
public class SavePieceResponse {
    final List<Suggestion> suggestions;
}

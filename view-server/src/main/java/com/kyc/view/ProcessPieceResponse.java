package com.kyc.view;

import java.util.List;

import lombok.Data;

@Data
public class ProcessPieceResponse {
    final List<Suggestion> suggestions;
}

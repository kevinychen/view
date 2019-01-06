package com.kyc.view;

import lombok.Data;

@Data
public class PieceSuggestion {
    final String code;
    /**
     * How good the match is. Over 2000 is a good match, over 3000 is a great one.
     */
    final double score;
}

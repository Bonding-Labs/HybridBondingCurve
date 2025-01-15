// SPDX-License-Identifier: UNLICENCED
// Copyright: Bonding Labs - Begic Nedim

import "./MathLib.sol";

/**
 * @title HybridBondingCurve
 * @notice Piecewise log->exp price formula: 
 *         if s < T => P= B*log(1 + s/L), else => B*exp((s-T)/E).
 */
library HybridBondingCurve {
    /**
     * @dev getPrice in 1e18 scale
     * @param supply current token supply
     * @param B base price scale
     * @param L early-phase sensitivity
     * @param E exponential steepness
     * @param T transition supply
     */
    function getPrice(
        uint256 supply,
        uint256 B,
        uint256 L,
        uint256 E,
        uint256 T
    ) internal pure returns (uint256) {
        if (supply < T) {
            // log regime
            uint256 ratio = (supply * 1e18) / L;
            uint256 logVal = MathLib.log1p(ratio);
            // scale result by B, then /1e18
            return (B * logVal) / 1e18;
        } else {
            // exp regime
            uint256 diff = supply > T ? (supply - T) : 0;
            int256 y = int256((diff * 1e18) / E);
            uint256 expVal = MathLib.expWad(y);
            return (B * expVal) / 1e18;
        }
    }
}

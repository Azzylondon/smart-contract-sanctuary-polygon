// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @dev Library to externalize the recallable feature to cut down on deployed 
 * bytecode in the main contract.
 * see {Recallable}
 */
library RecallManager {
    struct RecallTimeTracker {
        mapping(uint256 => uint32) bornOnDate;
    }

    /**
     * @dev If the bornOnDate for `_tokenId` + `_maxRecallPeriod` is later than 
     * the current timestamp, returns the amount of time remaining, in seconds.
     * @dev If the time is past, or if `_tokenId`  doesn't exist in `_tracker`, 
     * returns 0.
     */
    function recallTimeRemaining(
        RecallTimeTracker storage _tracker,
        uint256 _tokenId,
        uint32 _maxRecallPeriod
    ) external view returns (uint32) {
        uint32 currentTimestamp = uint32(block.timestamp);
        uint32 recallDeadline = _tracker.bornOnDate[_tokenId] +
            _maxRecallPeriod;
        if (currentTimestamp >= recallDeadline) {
            return uint32(0);
        }

        return recallDeadline - currentTimestamp;
    }

    /**
     * @dev Returns the `bornOnDate` for `_tokenId` as a Unix timestamp.
     * @dev If `_tokenId` doesn't exist in `_tracker`, returns 0.
     */
    function getBornOnDate(RecallTimeTracker storage _tracker, uint256 _tokenId)
        external
        view
        returns (uint32)
    {
        return _tracker.bornOnDate[_tokenId];
    }

    /**
     * @dev Returns true if `_tokenId` exists in `_tracker`.
     */
    function hasBornOnDate(RecallTimeTracker storage _tracker, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return _tracker.bornOnDate[_tokenId] != 0;
    }

    /**
     * @dev Sets the `bornOnDate` for `_tokenId` to the current timestamp.
     * @dev This should only be called when the token is minted.
     */
    function setBornOnDate(
        RecallTimeTracker storage _tracker,
        uint256 _tokenId
    ) external {
        require(!hasBornOnDate(_tracker, _tokenId));
        _tracker.bornOnDate[_tokenId] = uint32(block.timestamp);
    }

    /**
     * @dev Remove `_tokenId` from `_tracker`.
     * @dev This should be called when the token is burned, or when the end
     * customer has confirmed that they can access the token.
     */
    function clearBornOnDate(
        RecallTimeTracker storage _tracker,
        uint256 _tokenId
    ) external {
        require(hasBornOnDate(_tracker, _tokenId));
        delete _tracker.bornOnDate[_tokenId];
    }
}
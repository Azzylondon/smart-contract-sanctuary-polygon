// SPDX-License-Identifier:	AGPL-3.0

// AbstractMangrove.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML} from "./MgvLib.sol";

import {MgvOfferMaking} from "./MgvOfferMaking.sol";
import {MgvOfferTakingWithPermit} from "./MgvOfferTakingWithPermit.sol";
import {MgvGovernable} from "./MgvGovernable.sol";

/* `AbstractMangrove` inherits the three contracts that implement generic Mangrove functionality (`MgvGovernable`,`MgvOfferTakingWithPermit` and `MgvOfferMaking`) but does not implement the abstract functions. */
abstract contract AbstractMangrove is
  MgvGovernable,
  MgvOfferTakingWithPermit,
  MgvOfferMaking
{
  constructor(
    address governance,
    uint gasprice,
    uint gasmax,
    string memory contractName
  )
    MgvOfferTakingWithPermit(contractName)
    MgvGovernable(governance, gasprice, gasmax)
  {}
}

// SPDX-License-Identifier: Unlicense

// IERC20.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;
pragma abicoder v2;

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  function symbol() external view returns (string memory);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  /// for wETH contract
  function deposit() external payable;

  function withdraw(uint) external;

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier:	AGPL-3.0

// Mangrove.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, P} from "./MgvLib.sol";

import {AbstractMangrove} from "./AbstractMangrove.sol";

/* <a id="Mangrove"></a> The `Mangrove` contract implements the "normal" version of Mangrove, where the taker flashloans the desired amount to each maker. Each time, makers are called after the loan. When the order is complete, each maker is called once again (with the orderbook unlocked). */
contract Mangrove is AbstractMangrove {
  using P.OfferDetail for P.OfferDetail.t;

  constructor(
    address governance,
    uint gasprice,
    uint gasmax
  ) AbstractMangrove(governance, gasprice, gasmax, "Mangrove") {}

  function executeEnd(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
    override
  {}

  function beforePosthook(ML.SingleOrder memory sor) internal override {}

  /* ## Flashloan */
  /*
     `flashloan` is for the 'normal' mode of operation. It:
     1. Flashloans `takerGives` `inbound_tkn` from the taker to the maker and returns false if the loan fails.
     2. Runs `offerDetail.maker`'s `execute` function.
     3. Returns the result of the operations, with optional makerData to help the maker debug.
   */
  function flashloan(ML.SingleOrder calldata sor, address taker)
    external
    override
    returns (uint gasused)
  { unchecked {
    /* `flashloan` must be used with a call (hence the `external` modifier) so its effect can be reverted. But a call from the outside would be fatal. */
    require(msg.sender == address(this), "mgv/flashloan/protected");
    /* The transfer taker -> maker is in 2 steps. First, taker->mgv. Then
       mgv->maker. With a direct taker->maker transfer, if one of taker/maker
       is blacklisted, we can't tell which one. We need to know which one:
       if we incorrectly blame the taker, a blacklisted maker can block a pair forever; if we incorrectly blame the maker, a blacklisted taker can unfairly make makers fail all the time. Of course we assume the Mangrove is not blacklisted. Also note that this setup doesn't not work well with tokens that take fees or recompute balances at transfer time. */
    if (transferTokenFrom(sor.inbound_tkn, taker, address(this), sor.gives)) {
      if (
        transferToken(
          sor.inbound_tkn,
          sor.offerDetail.maker(),
          sor.gives
        )
      ) {
        gasused = makerExecute(sor);
      } else {
        innerRevert([bytes32("mgv/makerReceiveFail"), bytes32(0), ""]);
      }
    } else {
      innerRevert([bytes32("mgv/takerTransferFail"), "", ""]);
    }
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvGovernable.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {HasMgvEvents, P} from "./MgvLib.sol";
import {MgvRoot} from "./MgvRoot.sol";

contract MgvGovernable is MgvRoot {
  // using P.Offer for P.Offer.t;
  // using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  /* The `governance` address. Governance is the only address that can configure parameters. */
  address public governance;

  constructor(
    address _governance,
    uint _gasprice,
    uint gasmax
  ) MgvRoot() { unchecked {
    emit NewMgv();

    /* Initially, governance is open to anyone. */

    /* Initialize vault to governance address, and set initial gasprice and gasmax. */
    setVault(_governance);
    setGasprice(_gasprice);
    setGasmax(gasmax);
    /* Initialize governance to `_governance` after parameter setting. */
    setGovernance(_governance);
  }}

  /* ## `authOnly` check */

  function authOnly() internal view { unchecked {
    require(
      msg.sender == governance ||
        msg.sender == address(this) ||
        governance == address(0),
      "mgv/unauthorized"
    );
  }}

  /* # Set configuration and Mangrove state */

  /* ## Locals */
  /* ### `active` */
  function activate(
    address outbound_tkn,
    address inbound_tkn,
    uint fee,
    uint density,
    uint offer_gasbase
  ) public { unchecked {
    authOnly();
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].active(true);
    emit SetActive(outbound_tkn, inbound_tkn, true);
    setFee(outbound_tkn, inbound_tkn, fee);
    setDensity(outbound_tkn, inbound_tkn, density);
    setGasbase(outbound_tkn, inbound_tkn, offer_gasbase);
  }}

  function deactivate(address outbound_tkn, address inbound_tkn) public {
    authOnly();
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].active(false);
    emit SetActive(outbound_tkn, inbound_tkn, false);
  }

  /* ### `fee` */
  function setFee(
    address outbound_tkn,
    address inbound_tkn,
    uint fee
  ) public { unchecked {
    authOnly();
    /* `fee` is in basis points, i.e. in percents of a percent. */
    require(fee <= 500, "mgv/config/fee/<=500"); // at most 5%
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].fee(fee);
    emit SetFee(outbound_tkn, inbound_tkn, fee);
  }}

  /* ### `density` */
  /* Useless if `global.useOracle != 0` */
  function setDensity(
    address outbound_tkn,
    address inbound_tkn,
    uint density
  ) public { unchecked {
    authOnly();

    require(checkDensity(density), "mgv/config/density/112bits");
    //+clear+
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].density(density);
    emit SetDensity(outbound_tkn, inbound_tkn, density);
  }}

  /* ### `gasbase` */
  function setGasbase(
    address outbound_tkn,
    address inbound_tkn,
    uint offer_gasbase
  ) public { unchecked {
    authOnly();
    /* Checking the size of `offer_gasbase` is necessary to prevent a) data loss when copied to an `OfferDetail` struct, and b) overflow when used in calculations. */
    require(
      uint24(offer_gasbase) == offer_gasbase,
      "mgv/config/offer_gasbase/24bits"
    );
    //+clear+
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].offer_gasbase(offer_gasbase);
    emit SetGasbase(outbound_tkn, inbound_tkn, offer_gasbase);
  }}

  /* ## Globals */
  /* ### `kill` */
  function kill() public { unchecked {
    authOnly();
    internal_global = internal_global.dead(true);
    emit Kill();
  }}

  /* ### `gasprice` */
  /* Useless if `global.useOracle is != 0` */
  function setGasprice(uint gasprice) public { unchecked {
    authOnly();
    require(checkGasprice(gasprice), "mgv/config/gasprice/16bits");

    //+clear+

    internal_global = internal_global.gasprice(gasprice);
    emit SetGasprice(gasprice);
  }}

  /* ### `gasmax` */
  function setGasmax(uint gasmax) public { unchecked {
    authOnly();
    /* Since any new `gasreq` is bounded above by `config.gasmax`, this check implies that all offers' `gasreq` is 24 bits wide at most. */
    require(uint24(gasmax) == gasmax, "mgv/config/gasmax/24bits");
    //+clear+
    internal_global = internal_global.gasmax(gasmax);
    emit SetGasmax(gasmax);
  }}

  /* ### `governance` */
  function setGovernance(address governanceAddress) public { unchecked {
    authOnly();
    governance = governanceAddress;
    emit SetGovernance(governanceAddress);
  }}

  /* ### `vault` */
  function setVault(address vaultAddress) public { unchecked {
    authOnly();
    vault = vaultAddress;
    emit SetVault(vaultAddress);
  }}

  /* ### `monitor` */
  function setMonitor(address monitor) public { unchecked {
    authOnly();
    internal_global = internal_global.monitor(monitor);
    emit SetMonitor(monitor);
  }}

  /* ### `useOracle` */
  function setUseOracle(bool useOracle) public { unchecked {
    authOnly();
    internal_global = internal_global.useOracle(useOracle);
    emit SetUseOracle(useOracle);
  }}

  /* ### `notify` */
  function setNotify(bool notify) public { unchecked {
    authOnly();
    internal_global = internal_global.notify(notify);
    emit SetNotify(notify);
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvHasOffers.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, HasMgvEvents, IMgvMonitor,P} from "./MgvLib.sol";
import {MgvRoot} from "./MgvRoot.sol";

/* `MgvHasOffers` contains the state variables and functions common to both market-maker operations and market-taker operations. Mostly: storing offers, removing them, updating market makers' provisions. */
contract MgvHasOffers is MgvRoot {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Local for P.Local.t;
  /* # State variables */
  /* Given a `outbound_tkn`,`inbound_tkn` pair, the mappings `offers` and `offerDetails` associate two 256 bits words to each offer id. Those words encode information detailed in [`structs.js`](#structs.js).

     The mappings are `outbound_tkn => inbound_tkn => offerId => P.Offer.t|P.OfferDetail.t`.
   */
  mapping(address => mapping(address => mapping(uint => P.Offer.t)))
    public offers;
  mapping(address => mapping(address => mapping(uint => P.OfferDetail.t)))
    public offerDetails;

  /* Makers provision their possible penalties in the `balanceOf` mapping.

       Offers specify the amount of gas they require for successful execution ([`gasreq`](#structs.js/gasreq)). To minimize book spamming, market makers must provision a *penalty*, which depends on their `gasreq` and on the pair's [`offer_gasbase`](#structs.js/gasbase). This provision is deducted from their `balanceOf`. If an offer fails, part of that provision is given to the taker, as retribution. The exact amount depends on the gas used by the offer before failing.

       The Mangrove keeps track of their available balance in the `balanceOf` map, which is decremented every time a maker creates a new offer, and may be modified on offer updates/cancelations/takings.
     */
  mapping(address => uint) public balanceOf;

  /* # Read functions */
  /* Convenience function to get best offer of the given pair */
  function best(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (uint)
  { unchecked {
    P.Local.t local = locals[outbound_tkn][inbound_tkn];
    return local.best();
  }}

  /* Returns information about an offer in ABI-compatible structs. Do not use internally, would be a huge memory-copying waste. Use `offers[outbound_tkn][inbound_tkn]` and `offerDetails[outbound_tkn][inbound_tkn]` instead. */
  function offerInfo(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  ) external view returns (P.OfferStruct memory offer, P.OfferDetailStruct memory offerDetail) { unchecked {

    P.Offer.t _offer = offers[outbound_tkn][inbound_tkn][offerId];
    offer = _offer.to_struct();

    P.OfferDetail.t _offerDetail = offerDetails[outbound_tkn][inbound_tkn][offerId];
    offerDetail = _offerDetail.to_struct();
  }}

  /* # Provision debit/credit utility functions */
  /* `balanceOf` is in wei of ETH. */

  function debitWei(address maker, uint amount) internal { unchecked {
    uint makerBalance = balanceOf[maker];
    require(makerBalance >= amount, "mgv/insufficientProvision");
    balanceOf[maker] = makerBalance - amount;
    emit Debit(maker, amount);
  }}

  function creditWei(address maker, uint amount) internal { unchecked {
    balanceOf[maker] += amount;
    emit Credit(maker, amount);
  }}

  /* # Misc. low-level functions */
  /* ## Offer deletion */

  /* When an offer is deleted, it is marked as such by setting `gives` to 0. Note that provision accounting in the Mangrove aims to minimize writes. Each maker `fund`s the Mangrove to increase its balance. When an offer is created/updated, we compute how much should be reserved to pay for possible penalties. That amount can always be recomputed with `offerDetail.gasprice * (offerDetail.gasreq + offerDetail.offer_gasbase)`. The balance is updated to reflect the remaining available ethers.

     Now, when an offer is deleted, the offer can stay provisioned, or be `deprovision`ed. In the latter case, we set `gasprice` to 0, which induces a provision of 0. All code calling `dirtyDeleteOffer` with `deprovision` set to `true` must be careful to correctly account for where that provision is going (back to the maker's `balanceOf`, or sent to a taker as compensation). */
  function dirtyDeleteOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    P.Offer.t offer,
    P.OfferDetail.t offerDetail,
    bool deprovision
  ) internal { unchecked {
    offer = offer.gives(0);
    if (deprovision) {
      offerDetail = offerDetail.gasprice(0);
    }
    offers[outbound_tkn][inbound_tkn][offerId] = offer;
    offerDetails[outbound_tkn][inbound_tkn][offerId] = offerDetail;
  }}

  /* ## Stitching the orderbook */

  /* Connect the offers `betterId` and `worseId` through their `next`/`prev` pointers. For more on the book structure, see [`structs.js`](#structs.js). Used after executing an offer (or a segment of offers), after removing an offer, or moving an offer.

  **Warning**: calling with `betterId = 0` will set `worseId` as the best. So with `betterId = 0` and `worseId = 0`, it sets the book to empty and loses track of existing offers.

  **Warning**: may make memory copy of `local.best` stale. Returns new `local`. */
  function stitchOffers(
    address outbound_tkn,
    address inbound_tkn,
    uint betterId,
    uint worseId,
    P.Local.t local
  ) internal returns (P.Local.t) { unchecked {
    if (betterId != 0) {
      offers[outbound_tkn][inbound_tkn][betterId] = offers[outbound_tkn][inbound_tkn][betterId].next(worseId);
    } else {
      local = local.best(worseId);
    }

    if (worseId != 0) {
      offers[outbound_tkn][inbound_tkn][worseId] = offers[outbound_tkn][inbound_tkn][worseId].prev(betterId);
    }

    return local;
  }}

  /* ## Check offer is live */
  /* Check whether an offer is 'live', that is: inserted in the order book. The Mangrove holds a `outbound_tkn => inbound_tkn => id => P.Offer.t` mapping in storage. Offer ids that are not yet assigned or that point to since-deleted offer will point to an offer with `gives` field at 0. */
  function isLive(P.Offer.t offer) public pure returns (bool) { unchecked {
    return offer.gives() > 0;
  }}
}

// SPDX-License-Identifier: Unlicense

// MgvLib.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./IERC20.sol";
import "./MgvPack.sol" as P;

/* # Structs
The structs defined in `structs.js` have their counterpart as solidity structs that are easy to manipulate for outside contracts / callers of view functions. */

library MgvLib {
  /*
   Some miscellaneous data types useful to `Mangrove` and external contracts */
  //+clear+

  /* `SingleOrder` holds data about an order-offer match in a struct. Used by `marketOrder` and `internalSnipes` (and some of their nested functions) to avoid stack too deep errors. */
  struct SingleOrder {
    address outbound_tkn;
    address inbound_tkn;
    uint offerId;
    P.Offer.t offer;
    /* `wants`/`gives` mutate over execution. Initially the `wants`/`gives` from the taker's pov, then actual `wants`/`gives` adjusted by offer's price and volume. */
    uint wants;
    uint gives;
    /* `offerDetail` is only populated when necessary. */
    P.OfferDetail.t offerDetail;
    P.Global.t global;
    P.Local.t local;
  }

  /* <a id="MgvLib/OrderResult"></a> `OrderResult` holds additional data for the maker and is given to them _after_ they fulfilled an offer. It gives them their own returned data from the previous call, and an `mgvData` specifying whether the Mangrove encountered an error. */

  struct OrderResult {
    /* `makerdata` holds a message that was either returned by the maker or passed as revert message at the end of the trade execution*/
    bytes32 makerData;
    /* `mgvData` is an [internal Mangrove status](#MgvOfferTaking/statusCodes) code. */
    bytes32 mgvData;
  }
}

/* # Events
The events emitted for use by bots are listed here: */
contract HasMgvEvents {
  /* * Emitted at the creation of the new Mangrove contract on the pair (`inbound_tkn`, `outbound_tkn`)*/
  event NewMgv();

  /* Mangrove adds or removes wei from `maker`'s account */
  /* * Credit event occurs when an offer is removed from the Mangrove or when the `fund` function is called*/
  event Credit(address indexed maker, uint amount);
  /* * Debit event occurs when an offer is posted or when the `withdraw` function is called */
  event Debit(address indexed maker, uint amount);

  /* * Mangrove reconfiguration */
  event SetActive(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    bool value
  );
  event SetFee(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetGasbase(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offer_gasbase
  );
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetVault(address value);
  event SetUseOracle(bool value);
  event SetNotify(bool value);
  event SetGasmax(uint value);
  event SetDensity(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetGasprice(uint value);

  /* Market order execution */
  event OrderStart();
  event OrderComplete(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address taker,
    uint takerGot,
    uint takerGave,
    uint penalty
  );

  /* * Offer execution */
  event OfferSuccess(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives
  );

  /* Log information when a trade execution reverts or returns a non empty bytes32 word */
  event OfferFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives,
    // `mgvData` may only be `"mgv/makerRevert"`, `"mgv/makerAbort"`, `"mgv/makerTransferFail"` or `"mgv/makerReceiveFail"`
    bytes32 mgvData
  );

  /* Log information when a posthook reverts */
  event PosthookFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId
  );

  /* * After `permit` and `approve` */
  event Approval(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address owner,
    address spender,
    uint value
  );

  /* * Mangrove closure */
  event Kill();

  /* * An offer was created or updated.
  A few words about why we include a `prev` field, and why we don't include a
  `next` field: in theory clients should need neither `prev` nor a `next` field.
  They could just 1. Read the order book state at a given block `b`.  2. On
  every event, update a local copy of the orderbook.  But in practice, we do not
  want to force clients to keep a copy of the *entire* orderbook. There may be a
  long tail of spam. Now if they only start with the first $N$ offers and
  receive a new offer that goes to the end of the book, they cannot tell if
  there are missing offers between the new offer and the end of the local copy
  of the book.
  
  So we add a prev pointer so clients with only a prefix of the book can receive
  out-of-prefix offers and know what to do with them. The `next` pointer is an
  optimization useful in Solidity (we traverse fewer memory locations) but
  useless in client code.
  */
  event OfferWrite(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address maker,
    uint wants,
    uint gives,
    uint gasprice,
    uint gasreq,
    uint id,
    uint prev
  );

  /* * `offerId` was present and is now removed from the book. */
  event OfferRetract(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id
  );
}

/* # IMaker interface */
interface IMaker {
  /* Called upon offer execution. If the call returns normally with the first 32 bytes are 0, Mangrove will try to transfer funds; otherwise not. Returned data (truncated to leftmost 32 bytes) can be accessed during the call to `makerPosthook` in the `result.mgvData` field. To revert with a 32 bytes value, use something like:
     ```
     function tradeRevert(bytes32 data) internal pure {
       bytes memory revData = new bytes(32);
         assembly {
           mstore(add(revData, 32), data)
           revert(add(revData, 32), 32)
         }
     }
     ```
     */
  function makerExecute(MgvLib.SingleOrder calldata order)
    external
    returns (bytes32);

  /* Called after all offers of an order have been executed. Posthook of the last executed order is called first and full reentrancy into the Mangrove is enabled at this time. `order` recalls key arguments of the order that was processed and `result` recalls important information for updating the current offer. (see [above](#MgvLib/OrderResult))*/
  function makerPosthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata result
  ) external;
}

/* # ITaker interface */
interface ITaker {
  /* Inverted mangrove only: call to taker after loans went through */
  function takerTrade(
    address outbound_tkn,
    address inbound_tkn,
    // total amount of outbound_tkn token that was flashloaned to the taker
    uint totalGot,
    // total amount of inbound_tkn token that should be made available
    uint totalGives
  ) external;
}

/* # Monitor interface
If enabled, the monitor receives notification after each offer execution and is read for each pair's `gasprice` and `density`. */
interface IMgvMonitor {
  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker)
    external;

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker) external;

  function read(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (uint gasprice, uint density);
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvOfferMaking.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {IMaker, HasMgvEvents, P} from "./MgvLib.sol";
import {MgvHasOffers} from "./MgvHasOffers.sol";

/* `MgvOfferMaking` contains market-making-related functions. */
contract MgvOfferMaking is MgvHasOffers {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  /* # Public Maker operations
     ## New Offer */
  //+clear+
  /* In the Mangrove, makers and takers call separate functions. Market makers call `newOffer` to fill the book, and takers call functions such as `marketOrder` to consume it.  */

  //+clear+

  /* The following structs holds offer creation/update parameters in memory. This frees up stack space for local variables. */
  struct OfferPack {
    address outbound_tkn;
    address inbound_tkn;
    uint wants;
    uint gives;
    uint id;
    uint gasreq;
    uint gasprice;
    uint pivotId;
    P.Global.t global;
    P.Local.t local;
    // used on update only
    P.Offer.t oldOffer;
  }

  /* The function `newOffer` is for market makers only; no match with the existing book is done. A maker specifies how much `inbound_tkn` it `wants` and how much `outbound_tkn` it `gives`.

     It also specify with `gasreq` how much gas should be given when executing their offer.

     `gasprice` indicates an upper bound on the gasprice at which the maker is ready to be penalised if their offer fails. Any value below the Mangrove's internal `gasprice` configuration value will be ignored.

    `gasreq`, together with `gasprice`, will contribute to determining the penalty provision set aside by the Mangrove from the market maker's `balanceOf` balance.

  Offers are always inserted at the correct place in the book. This requires walking through offers to find the correct insertion point. As in [Oasis](https://github.com/daifoundation/maker-otc/blob/f2060c5fe12fe3da71ac98e8f6acc06bca3698f5/src/matching_market.sol#L493), the maker should find the id of an offer close to its own and provide it as `pivotId`.

  An offer cannot be inserted in a closed market, nor when a reentrancy lock for `outbound_tkn`,`inbound_tkn` is on.

  No more than $2^{24}-1$ offers can ever be created for one `outbound_tkn`,`inbound_tkn` pair.

  The actual contents of the function is in `writeOffer`, which is called by both `newOffer` and `updateOffer`.
  */
  function newOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId
  ) external payable returns (uint) { unchecked {
    /* In preparation for calling `writeOffer`, we read the `outbound_tkn`,`inbound_tkn` pair configuration, check for reentrancy and market liveness, fill the `OfferPack` struct and increment the `outbound_tkn`,`inbound_tkn` pair's `last`. */
    OfferPack memory ofp;
    (ofp.global, ofp.local) = config(outbound_tkn, inbound_tkn);
    unlockedMarketOnly(ofp.local);
    activeMarketOnly(ofp.global, ofp.local);
    if (msg.value > 0) {
      creditWei(msg.sender, msg.value);
    }

    ofp.id = 1 + ofp.local.last();
    require(uint32(ofp.id) == ofp.id, "mgv/offerIdOverflow");

    ofp.local = ofp.local.last(ofp.id);

    ofp.outbound_tkn = outbound_tkn;
    ofp.inbound_tkn = inbound_tkn;
    ofp.wants = wants;
    ofp.gives = gives;
    ofp.gasreq = gasreq;
    ofp.gasprice = gasprice;
    ofp.pivotId = pivotId;

    /* The second parameter to writeOffer indicates that we are creating a new offer, not updating an existing one. */
    writeOffer(ofp, false);

    /* Since we locally modified a field of the local configuration (`last`), we save the change to storage. Note that `writeOffer` may have further modified the local configuration by updating the current `best` offer. */
    locals[ofp.outbound_tkn][ofp.inbound_tkn] = ofp.local;
    return ofp.id;
  }}

  /* ## Update Offer */
  //+clear+
  /* Very similar to `newOffer`, `updateOffer` prepares an `OfferPack` for `writeOffer`. Makers should use it for updating live offers, but also to save on gas by reusing old, already consumed offers.

     A `pivotId` should still be given to minimise reads in the offer book. It is OK to give the offers' own id as a pivot.


     Gas use is minimal when:
     1. The offer does not move in the book
     2. The offer does not change its `gasreq`
     3. The (`outbound_tkn`,`inbound_tkn`)'s `offer_gasbase` has not changed since the offer was last written
     4. `gasprice` has not changed since the offer was last written
     5. `gasprice` is greater than the Mangrove's gasprice estimation
  */
  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable { unchecked {
    OfferPack memory ofp;
    (ofp.global, ofp.local) = config(outbound_tkn, inbound_tkn);
    unlockedMarketOnly(ofp.local);
    activeMarketOnly(ofp.global, ofp.local);
    if (msg.value > 0) {
      creditWei(msg.sender, msg.value);
    }
    ofp.outbound_tkn = outbound_tkn;
    ofp.inbound_tkn = inbound_tkn;
    ofp.wants = wants;
    ofp.gives = gives;
    ofp.id = offerId;
    ofp.gasreq = gasreq;
    ofp.gasprice = gasprice;
    ofp.pivotId = pivotId;
    ofp.oldOffer = offers[outbound_tkn][inbound_tkn][offerId];
    // Save local config
    P.Local.t oldLocal = ofp.local;
    /* The second argument indicates that we are updating an existing offer, not creating a new one. */
    writeOffer(ofp, true);
    /* We saved the current pair's configuration before calling `writeOffer`, since that function may update the current `best` offer. We now check for any change to the configuration and update it if needed. */
    if (!oldLocal.eq(ofp.local)) {
      locals[ofp.outbound_tkn][ofp.inbound_tkn] = ofp.local;
    }
  }}

  /* ## Retract Offer */
  //+clear+
  /* `retractOffer` takes the offer `offerId` out of the book. However, `deprovision == true` also refunds the provision associated with the offer. */
  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision
  ) external returns (uint provision) { unchecked {
    (, P.Local.t local) = config(outbound_tkn, inbound_tkn);
    unlockedMarketOnly(local);
    P.Offer.t offer = offers[outbound_tkn][inbound_tkn][offerId];
    P.OfferDetail.t offerDetail = offerDetails[outbound_tkn][inbound_tkn][offerId];
    require(
      msg.sender == offerDetail.maker(),
      "mgv/retractOffer/unauthorized"
    );

    /* Here, we are about to un-live an offer, so we start by taking it out of the book by stitching together its previous and next offers. Note that unconditionally calling `stitchOffers` would break the book since it would connect offers that may have since moved. */
    if (isLive(offer)) {
      P.Local.t oldLocal = local;
      local = stitchOffers(
        outbound_tkn,
        inbound_tkn,
        offer.prev(),
        offer.next(),
        local
      );
      /* If calling `stitchOffers` has changed the current `best` offer, we update the storage. */
      if (!oldLocal.eq(local)) {
        locals[outbound_tkn][inbound_tkn] = local;
      }
    }
    /* Set `gives` to 0. Moreover, the last argument depends on whether the user wishes to get their provision back (if true, `gasprice` will be set to 0 as well). */
    dirtyDeleteOffer(
      outbound_tkn,
      inbound_tkn,
      offerId,
      offer,
      offerDetail,
      deprovision
    );

    /* If the user wants to get their provision back, we compute its provision from the offer's `gasprice`, `offer_gasbase` and `gasreq`. */
    if (deprovision) {
      provision =
        10**9 *
        offerDetail.gasprice() * //gasprice is 0 if offer was deprovisioned
        (offerDetail.gasreq() + offerDetail.offer_gasbase());
      // credit `balanceOf` and log transfer
      creditWei(msg.sender, provision);
    }
    emit OfferRetract(outbound_tkn, inbound_tkn, offerId);
  }}

  /* ## Provisioning
  Market makers must have enough provisions for possible penalties. These provisions are in ETH. Every time a new offer is created or an offer is updated, `balanceOf` is adjusted to provision the offer's maximum possible penalty (`gasprice * (gasreq + offer_gasbase)`).

  For instance, if the current `balanceOf` of a maker is 1 ether and they create an offer that requires a provision of 0.01 ethers, their `balanceOf` will be reduced to 0.99 ethers. No ethers will move; this is just an internal accounting movement to make sure the maker cannot `withdraw` the provisioned amounts.

  */
  //+clear+

  /* Fund should be called with a nonzero value (hence the `payable` modifier). The provision will be given to `maker`, not `msg.sender`. */
  function fund(address maker) public payable { unchecked {
    (P.Global.t _global, ) = config(address(0), address(0));
    liveMgvOnly(_global);
    creditWei(maker, msg.value);
  }}

  function fund() external payable { unchecked {
    fund(msg.sender);
  }}

  /* A transfer with enough gas to the Mangrove will increase the caller's available `balanceOf` balance. _You should send enough gas to execute this function when sending money to the Mangrove._  */
  receive() external payable { unchecked {
    fund(msg.sender);
  }}

  /* Any provision not currently held to secure an offer's possible penalty is available for withdrawal. */
  function withdraw(uint amount) external returns (bool noRevert) { unchecked {
    /* Since we only ever send money to the caller, we do not need to provide any particular amount of gas, the caller should manage this herself. */
    debitWei(msg.sender, amount);
    (noRevert, ) = msg.sender.call{value: amount}("");
  }}

  /* # Low-level Maker functions */

  /* ## Write Offer */

  function writeOffer(OfferPack memory ofp, bool update) internal { unchecked {
    /* `gasprice`'s floor is Mangrove's own gasprice estimate, `ofp.global.gasprice`. We first check that gasprice fits in 16 bits. Otherwise it could be that `uint16(gasprice) < global_gasprice < gasprice`, and the actual value we store is `uint16(gasprice)`. */
    require(
      uint16(ofp.gasprice) == ofp.gasprice,
      "mgv/writeOffer/gasprice/16bits"
    );

    if (ofp.gasprice < ofp.global.gasprice()) {
      ofp.gasprice = ofp.global.gasprice();
    }

    /* * Check `gasreq` below limit. Implies `gasreq` at most 24 bits wide, which ensures no overflow in computation of `provision` (see below). */
    require(
      ofp.gasreq <= ofp.global.gasmax(),
      "mgv/writeOffer/gasreq/tooHigh"
    );
    /* * Make sure `gives > 0` -- division by 0 would throw in several places otherwise, and `isLive` relies on it. */
    require(ofp.gives > 0, "mgv/writeOffer/gives/tooLow");
    /* * Make sure that the maker is posting a 'dense enough' offer: the ratio of `outbound_tkn` offered per gas consumed must be high enough. The actual gas cost paid by the taker is overapproximated by adding `offer_gasbase` to `gasreq`. */
    require(
      ofp.gives >=
        (ofp.gasreq + ofp.local.offer_gasbase()) * ofp.local.density(),
      "mgv/writeOffer/density/tooLow"
    );

    /* The following checks are for the maker's convenience only. */
    require(uint96(ofp.gives) == ofp.gives, "mgv/writeOffer/gives/96bits");
    require(uint96(ofp.wants) == ofp.wants, "mgv/writeOffer/wants/96bits");

    /* The position of the new or updated offer is found using `findPosition`. If the offer is the best one, `prev == 0`, and if it's the last in the book, `next == 0`.

       `findPosition` is only ever called here, but exists as a separate function to make the code easier to read.

    **Warning**: `findPosition` will call `better`, which may read the offer's `offerDetails`. So it is important to find the offer position _before_ we update its `offerDetail` in storage. We waste 1 (hot) read in that case but we deem that the code would get too ugly if we passed the old `offerDetail` as argument to `findPosition` and to `better`, just to save 1 hot read in that specific case.  */
    (uint prev, uint next) = findPosition(ofp);

    /* Log the write offer event. */
    emit OfferWrite(
      ofp.outbound_tkn,
      ofp.inbound_tkn,
      msg.sender,
      ofp.wants,
      ofp.gives,
      ofp.gasprice,
      ofp.gasreq,
      ofp.id,
      prev
    );

    /* We now write the new `offerDetails` and remember the previous provision (0 by default, for new offers) to balance out maker's `balanceOf`. */
    uint oldProvision;
    {
      P.OfferDetail.t offerDetail = offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][
        ofp.id
      ];
      if (update) {
        require(
          msg.sender == offerDetail.maker(),
          "mgv/updateOffer/unauthorized"
        );
        oldProvision =
          10**9 *
          offerDetail.gasprice() *
          (offerDetail.gasreq() + offerDetail.offer_gasbase());
      }

      /* If the offer is new, has a new `gasprice`, `gasreq`, or if the Mangrove's `offer_gasbase` configuration parameter has changed, we also update `offerDetails`. */
      if (
        !update ||
        offerDetail.gasreq() != ofp.gasreq ||
        offerDetail.gasprice() != ofp.gasprice ||
        offerDetail.offer_gasbase() !=
        ofp.local.offer_gasbase()
      ) {
        uint offer_gasbase = ofp.local.offer_gasbase();
        offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][ofp.id] = 
        P.OfferDetail.pack({
          __maker: msg.sender,
          __gasreq: ofp.gasreq,
          __offer_gasbase: offer_gasbase,
          __gasprice: ofp.gasprice
        });
      }
    }

    /* With every change to an offer, a maker may deduct provisions from its `balanceOf` balance. It may also get provisions back if the updated offer requires fewer provisions than before. */
    {
      uint provision = (ofp.gasreq +
        ofp.local.offer_gasbase()) *
        ofp.gasprice *
        10**9;
      if (provision > oldProvision) {
        debitWei(msg.sender, provision - oldProvision);
      } else if (provision < oldProvision) {
        creditWei(msg.sender, oldProvision - provision);
      }
    }
    /* We now place the offer in the book at the position found by `findPosition`. */

    /* First, we test if the offer has moved in the book or is not currently in the book. If `!isLive(ofp.oldOffer)`, we must update its prev/next. If it is live but its prev has changed, we must also update them. Note that checking both `prev = oldPrev` and `next == oldNext` would be redundant. If either is true, then the updated offer has not changed position and there is nothing to update.

    As a note for future changes, there is a tricky edge case where `prev == oldPrev` yet the prev/next should be changed: a previously-used offer being brought back in the book, and ending with the same prev it had when it was in the book. In that case, the neighbor is currently pointing to _another_ offer, and thus must be updated. With the current code structure, this is taken care of as a side-effect of checking `!isLive`, but should be kept in mind. The same goes in the `next == oldNext` case. */
    if (!isLive(ofp.oldOffer) || prev != ofp.oldOffer.prev()) {
      /* * If the offer is not the best one, we update its predecessor; otherwise we update the `best` value. */
      if (prev != 0) {
        offers[ofp.outbound_tkn][ofp.inbound_tkn][prev] = offers[ofp.outbound_tkn][ofp.inbound_tkn][prev].next(ofp.id);
      } else {
        ofp.local = ofp.local.best(ofp.id);
      }

      /* * If the offer is not the last one, we update its successor. */
      if (next != 0) {
        offers[ofp.outbound_tkn][ofp.inbound_tkn][next] = offers[ofp.outbound_tkn][ofp.inbound_tkn][next].prev(ofp.id);
      }

      /* * Recall that in this branch, the offer has changed location, or is not currently in the book. If the offer is not new and already in the book, we must remove it from its previous location by stitching its previous prev/next. */
      if (update && isLive(ofp.oldOffer)) {
        ofp.local = stitchOffers(
          ofp.outbound_tkn,
          ofp.inbound_tkn,
          ofp.oldOffer.prev(),
          ofp.oldOffer.next(),
          ofp.local
        );
      }
    }

    /* With the `prev`/`next` in hand, we finally store the offer in the `offers` map. */
    P.Offer.t ofr = P.Offer.pack({
      __prev: prev,
      __next: next,
      __wants: ofp.wants,
      __gives: ofp.gives
    });
    offers[ofp.outbound_tkn][ofp.inbound_tkn][ofp.id] = ofr;
  }}

  /* ## Find Position */
  /* `findPosition` takes a price in the form of a (`ofp.wants`,`ofp.gives`) pair, an offer id (`ofp.pivotId`) and walks the book from that offer (backward or forward) until the right position for the price is found. The position is returned as a `(prev,next)` pair, with `prev` or `next` at 0 to mark the beginning/end of the book (no offer ever has id 0).

  If prices are equal, `findPosition` will put the newest offer last. */
  function findPosition(OfferPack memory ofp)
    internal
    view
    returns (uint, uint)
  { unchecked {
    uint prevId;
    uint nextId;
    uint pivotId = ofp.pivotId;
    /* Get `pivot`, optimizing for the case where pivot info is already known */
    P.Offer.t pivot = pivotId == ofp.id
      ? ofp.oldOffer
      : offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotId];

    /* In case pivotId is not an active offer, it is unusable (since it is out of the book). We default to the current best offer. If the book is empty pivot will be 0. That is handled through a test in the `better` comparison function. */
    if (!isLive(pivot)) {
      pivotId = ofp.local.best();
      pivot = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotId];
    }

    /* * Pivot is better than `wants/gives`, we follow `next`. */
    if (better(ofp, pivot, pivotId)) {
      P.Offer.t pivotNext;
      while (pivot.next() != 0) {
        uint pivotNextId = pivot.next();
        pivotNext = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotNextId];
        if (better(ofp, pivotNext, pivotNextId)) {
          pivotId = pivotNextId;
          pivot = pivotNext;
        } else {
          break;
        }
      }
      // gets here on empty book
      (prevId, nextId) = (pivotId, pivot.next());

      /* * Pivot is strictly worse than `wants/gives`, we follow `prev`. */
    } else {
      P.Offer.t pivotPrev;
      while (pivot.prev() != 0) {
        uint pivotPrevId = pivot.prev();
        pivotPrev = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotPrevId];
        if (better(ofp, pivotPrev, pivotPrevId)) {
          break;
        } else {
          pivotId = pivotPrevId;
          pivot = pivotPrev;
        }
      }

      (prevId, nextId) = (pivot.prev(), pivotId);
    }

    return (
      prevId == ofp.id ? ofp.oldOffer.prev() : prevId,
      nextId == ofp.id ? ofp.oldOffer.next() : nextId
    );
  }}

  /* ## Better */
  /* The utility method `better` takes an offer represented by `ofp` and another represented by `offer1`. It returns true iff `offer1` is better or as good as `ofp`.
    "better" is defined on the lexicographic order $\textrm{price} \times_{\textrm{lex}} \textrm{density}^{-1}$. This means that for the same price, offers that deliver more volume per gas are taken first.

      In addition to `offer1`, we also provide its id, `offerId1` in order to save gas. If necessary (ie. if the prices `wants1/gives1` and `wants2/gives2` are the same), we read storage to get `gasreq1` at `offerDetails[...][offerId1]. */
  function better(
    OfferPack memory ofp,
    P.Offer.t offer1,
    uint offerId1
  ) internal view returns (bool) { unchecked {
    if (offerId1 == 0) {
      /* Happens on empty book. Returning `false` would work as well due to specifics of `findPosition` but true is more consistent. Here we just want to avoid reading `offerDetail[...][0]` for nothing. */
      return true;
    }
    uint wants1 = offer1.wants();
    uint gives1 = offer1.gives();
    uint wants2 = ofp.wants;
    uint gives2 = ofp.gives;
    uint weight1 = wants1 * gives2;
    uint weight2 = wants2 * gives1;
    if (weight1 == weight2) {
      uint gasreq1 = 
          offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][offerId1].gasreq();
      uint gasreq2 = ofp.gasreq;
      return (gives1 * gasreq2 >= gives2 * gasreq1);
    } else {
      return weight1 < weight2;
    }
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvOfferTaking.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {IERC20, HasMgvEvents, IMaker, IMgvMonitor, MgvLib as ML, P} from "./MgvLib.sol";
import {MgvHasOffers} from "./MgvHasOffers.sol";

abstract contract MgvOfferTaking is MgvHasOffers {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;
  /* # MultiOrder struct */
  /* The `MultiOrder` struct is used by market orders and snipes. Some of its fields are only used by market orders (`initialWants, initialGives`). We need a common data structure for both since low-level calls are shared between market orders and snipes. The struct is helpful in decreasing stack use. */
  struct MultiOrder {
    uint initialWants; // used globally by market order, not used by snipes
    uint initialGives; // used globally by market order, not used by snipes
    uint totalGot; // used globally by market order, per-offer by snipes
    uint totalGave; // used globally by market order, per-offer by snipes
    uint totalPenalty; // used globally
    address taker; // used globally
    bool fillWants; // used globally
  }

  /* # Market Orders */

  /* ## Market Order */
  //+clear+

  /* A market order specifies a (`outbound_tkn`,`inbound_tkn`) pair, a desired total amount of `outbound_tkn` (`takerWants`), and an available total amount of `inbound_tkn` (`takerGives`). It returns two `uint`s: the total amount of `outbound_tkn` received and the total amount of `inbound_tkn` spent.

     The `takerGives/takerWants` ratio induces a maximum average price that the taker is ready to pay across all offers that will be executed during the market order. It is thus possible to execute an offer with a price worse than the initial (`takerGives`/`takerWants`) ratio given as argument to `marketOrder` if some cheaper offers were executed earlier in the market order.

  The market order stops when the price has become too high, or when the end of the book has been reached, or:
  * If `fillWants` is true, the market order stops when `takerWants` units of `outbound_tkn` have been obtained. With `fillWants` set to true, to buy a specific volume of `outbound_tkn` at any price, set `takerWants` to the amount desired and `takerGives` to $2^{160}-1$.
  * If `fillWants` is false, the taker is filling `gives` instead: the market order stops when `takerGives` units of `inbound_tkn` have been sold. With `fillWants` set to false, to sell a specific volume of `inbound_tkn` at any price, set `takerGives` to the amount desired and `takerWants` to $0$. */
  function marketOrder(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants
  )
    external
    returns (
      uint,
      uint,
      uint
    )
  { unchecked {
    return
      generalMarketOrder(
        outbound_tkn,
        inbound_tkn,
        takerWants,
        takerGives,
        fillWants,
        msg.sender
      );
  }}

  /* # General Market Order */
  //+clear+
  /* General market orders set up the market order with a given `taker` (`msg.sender` in the most common case). Returns `(totalGot, totalGave)`.
  Note that the `taker` can be anyone. This is safe when `taker == msg.sender`, but `generalMarketOrder` must not be called with `taker != msg.sender` unless a security check is done after (see [`MgvOfferTakingWithPermit`](#mgvoffertakingwithpermit.sol)`. */
  function generalMarketOrder(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants,
    address taker
  )
    internal
    returns (
      uint,
      uint,
      uint
    )
  { unchecked {
    /* Since amounts stored in offers are 96 bits wide, checking that `takerWants` and `takerGives` fit in 160 bits prevents overflow during the main market order loop. */
    require(uint160(takerWants) == takerWants, "mgv/mOrder/takerWants/160bits");
    require(uint160(takerGives) == takerGives, "mgv/mOrder/takerGives/160bits");

    /* `SingleOrder` is defined in `MgvLib.sol` and holds information for ordering the execution of one offer. */
    ML.SingleOrder memory sor;
    sor.outbound_tkn = outbound_tkn;
    sor.inbound_tkn = inbound_tkn;
    (sor.global, sor.local) = config(outbound_tkn, inbound_tkn);
    /* Throughout the execution of the market order, the `sor`'s offer id and other parameters will change. We start with the current best offer id (0 if the book is empty). */
    sor.offerId = sor.local.best();
    sor.offer = offers[outbound_tkn][inbound_tkn][sor.offerId];
    /* `sor.wants` and `sor.gives` may evolve, but they are initially however much remains in the market order. */
    sor.wants = takerWants;
    sor.gives = takerGives;

    /* `MultiOrder` (defined above) maintains information related to the entire market order. During the order, initial `wants`/`gives` values minus the accumulated amounts traded so far give the amounts that remain to be traded. */
    MultiOrder memory mor;
    mor.initialWants = takerWants;
    mor.initialGives = takerGives;
    mor.taker = taker;
    mor.fillWants = fillWants;

    /* For the market order to even start, the market needs to be both active, and not currently protected from reentrancy. */
    activeMarketOnly(sor.global, sor.local);
    unlockedMarketOnly(sor.local);

    /* ### Initialization */
    /* The market order will operate as follows : it will go through offers from best to worse, starting from `offerId`, and: */
    /* * will maintain remaining `takerWants` and `takerGives` values. The initial `takerGives/takerWants` ratio is the average price the taker will accept. Better prices may be found early in the book, and worse ones later.
     * will not set `prev`/`next` pointers to their correct locations at each offer taken (this is an optimization enabled by forbidding reentrancy).
     * after consuming a segment of offers, will update the current `best` offer to be the best remaining offer on the book. */

    /* We start be enabling the reentrancy lock for this (`outbound_tkn`,`inbound_tkn`) pair. */
    sor.local = sor.local.lock(true);
    locals[outbound_tkn][inbound_tkn] = sor.local;

    emit OrderStart();

    /* Call recursive `internalMarketOrder` function.*/
    internalMarketOrder(mor, sor, true);

    /* Over the course of the market order, a penalty reserved for `msg.sender` has accumulated in `mor.totalPenalty`. No actual transfers have occured yet -- all the ethers given by the makers as provision are owned by the Mangrove. `sendPenalty` finally gives the accumulated penalty to `msg.sender`. */
    sendPenalty(mor.totalPenalty);

    emit OrderComplete(
      outbound_tkn,
      inbound_tkn,
      taker,
      mor.totalGot,
      mor.totalGave,
      mor.totalPenalty
    );

    //+clear+
    return (mor.totalGot, mor.totalGave, mor.totalPenalty);
  }}

  /* ## Internal market order */
  //+clear+
  /* `internalMarketOrder` works recursively. Going downward, each successive offer is executed until the market order stops (due to: volume exhausted, bad price, or empty book). Then the [reentrancy lock is lifted](#internalMarketOrder/liftReentrancy). Going upward, each offer's `maker` contract is called again with its remaining gas and given the chance to update its offers on the book.

    The last argument is a boolean named `proceed`. If an offer was not executed, it means the price has become too high. In that case, we notify the next recursive call that the market order should end. In this initial call, no offer has been executed yet so `proceed` is true. */
  function internalMarketOrder(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    bool proceed
  ) internal { unchecked {
    /* #### Case 1 : End of order */
    /* We execute the offer currently stored in `sor`. */
    if (
      proceed &&
      (mor.fillWants ? sor.wants > 0 : sor.gives > 0) &&
      sor.offerId > 0
    ) {
      uint gasused; // gas used by `makerExecute`
      bytes32 makerData; // data returned by maker

      /* <a id="MgvOfferTaking/statusCodes"></a> `mgvData` is an internal Mangrove status code. It may appear in an [`OrderResult`](#MgvLib/OrderResult). Its possible values are:
      * `"mgv/notExecuted"`: offer was not executed.
      * `"mgv/tradeSuccess"`: offer execution succeeded. Will appear in `OrderResult`.
      * `"mgv/notEnoughGasForMakerTrade"`: cannot give maker close enough to `gasreq`. Triggers a revert of the entire order.
      * `"mgv/makerRevert"`: execution of `makerExecute` reverted. Will appear in `OrderResult`.
      * `"mgv/makerAbort"`: execution of `makerExecute` returned normally, but returndata did not start with 32 bytes of 0s. Will appear in `OrderResult`.
      * `"mgv/makerTransferFail"`: maker could not send outbound_tkn tokens. Will appear in `OrderResult`.
      * `"mgv/makerReceiveFail"`: maker could not receive inbound_tkn tokens. Will appear in `OrderResult`.
      * `"mgv/takerTransferFail"`: taker could not send inbound_tkn tokens. Triggers a revert of the entire order.

      `mgvData` should not be exploitable by the maker! */
      bytes32 mgvData;

      /* Load additional information about the offer. We don't do it earlier to save one storage read in case `proceed` was false. */
      sor.offerDetail = offerDetails[sor.outbound_tkn][sor.inbound_tkn][
        sor.offerId
      ];

      /* `execute` will adjust `sor.wants`,`sor.gives`, and may attempt to execute the offer if its price is low enough. It is crucial that an error due to `taker` triggers a revert. That way, [`mgvData`](#MgvOfferTaking/statusCodes) not in `["mgv/notExecuted","mgv/tradeSuccess"]` means the failure is the maker's fault. */
      /* Post-execution, `sor.wants`/`sor.gives` reflect how much was sent/taken by the offer. We will need it after the recursive call, so we save it in local variables. Same goes for `offerId`, `sor.offer` and `sor.offerDetail`. */

      (gasused, makerData, mgvData) = execute(mor, sor);

      /* Keep cached copy of current `sor` values. */
      uint takerWants = sor.wants;
      uint takerGives = sor.gives;
      uint offerId = sor.offerId;
      P.Offer.t offer = sor.offer;
      P.OfferDetail.t offerDetail = sor.offerDetail;

      /* If an execution was attempted, we move `sor` to the next offer. Note that the current state is inconsistent, since we have not yet updated `sor.offerDetails`. */
      if (mgvData != "mgv/notExecuted") {
        sor.wants = mor.initialWants > mor.totalGot
          ? mor.initialWants - mor.totalGot
          : 0;
        /* It is known statically that `mor.initialGives - mor.totalGave` does not underflow since
           1. `mor.totalGave` was increased by `sor.gives` during `execute`,
           2. `sor.gives` was at most `mor.initialGives - mor.totalGave` from earlier step,
           3. `sor.gives` may have been clamped _down_ during `execute` (to "`offer.wants`" if the offer is entirely consumed, or to `makerWouldWant`, cf. code of `execute`).
        */
        sor.gives = mor.initialGives - mor.totalGave;
        sor.offerId = sor.offer.next();
        sor.offer = offers[sor.outbound_tkn][sor.inbound_tkn][sor.offerId];
      }

      /* note that internalMarketOrder may be called twice with same offerId, but in that case `proceed` will be false! */
      internalMarketOrder(
        mor,
        sor,
        /* `proceed` value for next call. Currently, when an offer did not execute, it's because the offer's price was too high. In that case we interrupt the loop and let the taker leave with less than they asked for (but at a correct price). We could also revert instead of breaking; this could be a configurable flag for the taker to pick. */
        mgvData != "mgv/notExecuted"
      );

      /* Restore `sor` values from to before recursive call */
      sor.offerId = offerId;
      sor.wants = takerWants;
      sor.gives = takerGives;
      sor.offer = offer;
      sor.offerDetail = offerDetail;

      /* After an offer execution, we may run callbacks and increase the total penalty. As that part is common to market orders and snipes, it lives in its own `postExecute` function. */
      if (mgvData != "mgv/notExecuted") {
        postExecute(mor, sor, gasused, makerData, mgvData);
      }

      /* #### Case 2 : End of market order */
      /* If `proceed` is false, the taker has gotten its requested volume, or we have reached the end of the book, we conclude the market order. */
    } else {
      /* During the market order, all executed offers have been removed from the book. We end by stitching together the `best` offer pointer and the new best offer. */
      sor.local = stitchOffers(
        sor.outbound_tkn,
        sor.inbound_tkn,
        0,
        sor.offerId,
        sor.local
      );
      /* <a id="internalMarketOrder/liftReentrancy"></a>Now that the market order is over, we can lift the lock on the book. In the same operation we

      * lift the reentrancy lock, and
      * update the storage

      so we are free from out of order storage writes.
      */
      sor.local = sor.local.lock(false);
      locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;

      /* `payTakerMinusFees` sends the fee to the vault, proportional to the amount purchased, and gives the rest to the taker */
      payTakerMinusFees(mor, sor);

      /* In an inverted Mangrove, amounts have been lent by each offer's maker to the taker. We now call the taker. This is a noop in a normal Mangrove. */
      executeEnd(mor, sor);
    }
  }}

  /* # Sniping */
  /* ## Snipes */
  //+clear+

  /* `snipes` executes multiple offers. It takes a `uint[4][]` as penultimate argument, with each array element of the form `[offerId,takerWants,takerGives,offerGasreq]`. The return parameters are of the form `(successes,snipesGot,snipesGave,bounty)`. 
  Note that we do not distinguish further between mismatched arguments/offer fields on the one hand, and an execution failure on the other. Still, a failed offer has to pay a penalty, and ultimately transaction logs explicitly mention execution failures (see `MgvLib.sol`). */
  function snipes(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants
  )
    external
    returns (
      uint,
      uint,
      uint,
      uint
    )
  { unchecked {
    return
      generalSnipes(outbound_tkn, inbound_tkn, targets, fillWants, msg.sender);
  }}

  /*
     From an array of _n_ `[offerId, takerWants,takerGives,gasreq]` elements, execute each snipe in sequence. Returns `(successes, takerGot, takerGave, bounty)`. 

     Note that if this function is not internal, anyone can make anyone use Mangrove.
     Note that unlike general market order, the returned total values are _not_ `mor.totalGot` and `mor.totalGave`, since those are reset at every iteration of the `targets` array. Instead, accumulators `snipesGot` and `snipesGave` are used. */
  function generalSnipes(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants,
    address taker
  )
    internal
    returns (
      uint,
      uint,
      uint,
      uint
    )
  { unchecked {
    ML.SingleOrder memory sor;
    sor.outbound_tkn = outbound_tkn;
    sor.inbound_tkn = inbound_tkn;
    (sor.global, sor.local) = config(outbound_tkn, inbound_tkn);

    MultiOrder memory mor;
    mor.taker = taker;
    mor.fillWants = fillWants;

    /* For the snipes to even start, the market needs to be both active and not currently protected from reentrancy. */
    activeMarketOnly(sor.global, sor.local);
    unlockedMarketOnly(sor.local);

    emit OrderStart();

    /* ### Main loop */
    //+clear+

    /* Call `internalSnipes` function. */
    (uint successCount, uint snipesGot, uint snipesGave) = internalSnipes(mor, sor, targets);

    /* Over the course of the snipes order, a penalty reserved for `msg.sender` has accumulated in `mor.totalPenalty`. No actual transfers have occured yet -- all the ethers given by the makers as provision are owned by the Mangrove. `sendPenalty` finally gives the accumulated penalty to `msg.sender`. */
    sendPenalty(mor.totalPenalty);
    //+clear+

    emit OrderComplete(
      outbound_tkn,
      inbound_tkn,
      taker,
      snipesGot,
      snipesGave,
      mor.totalPenalty
    );

    return (successCount, snipesGot, snipesGave, mor.totalPenalty);
  }}

  /* ## Internal snipes */
  //+clear+
  /* `internalSnipes` works by looping over targets. Each successive offer is executed under a [reentrancy lock](#internalSnipes/liftReentrancy), then its posthook is called.y lock [is lifted](). Going upward, each offer's `maker` contract is called again with its remaining gas and given the chance to update its offers on the book. */
  function internalSnipes(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    uint[4][] calldata targets
  ) internal returns (uint successCount, uint snipesGot, uint snipesGave) { unchecked {
    for (uint i = 0; i < targets.length; i++) {
      /* Reset these amounts since every snipe is treated individually. Only the total penalty is sent at the end of all snipes. */
      mor.totalGot = 0;
      mor.totalGave = 0;

      /* Initialize single order struct. */
      sor.offerId = targets[i][0];
      sor.offer = offers[sor.outbound_tkn][sor.inbound_tkn][sor.offerId];
      sor.offerDetail = offerDetails[sor.outbound_tkn][sor.inbound_tkn][
        sor.offerId
      ];

      /* If we removed the `isLive` conditional, a single expired or nonexistent offer in `targets` would revert the entire transaction (by the division by `offer.gives` below since `offer.gives` would be 0). We also check that `gasreq` is not worse than specified. A taker who does not care about `gasreq` can specify any amount larger than $2^{24}-1$. A mismatched price will be detected by `execute`. */
      if (
        !isLive(sor.offer) ||
        sor.offerDetail.gasreq() > targets[i][3]
      ) {
        /* We move on to the next offer in the array. */
        continue;
      } else {
        require(
          uint96(targets[i][1]) == targets[i][1],
          "mgv/snipes/takerWants/96bits"
        );
        require(
          uint96(targets[i][2]) == targets[i][2],
          "mgv/snipes/takerGives/96bits"
        );
        sor.wants = targets[i][1];
        sor.gives = targets[i][2];

        /* We start be enabling the reentrancy lock for this (`outbound_tkn`,`inbound_tkn`) pair. */
        sor.local = sor.local.lock(true);
        locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;

        /* `execute` will adjust `sor.wants`,`sor.gives`, and may attempt to execute the offer if its price is low enough. It is crucial that an error due to `taker` triggers a revert. That way [`mgvData`](#MgvOfferTaking/statusCodes) not in `["mgv/tradeSuccess","mgv/notExecuted"]` means the failure is the maker's fault. */
        /* Post-execution, `sor.wants`/`sor.gives` reflect how much was sent/taken by the offer. */
        (uint gasused, bytes32 makerData, bytes32 mgvData) = execute(mor, sor);

        if (mgvData == "mgv/tradeSuccess") {
          successCount += 1;
        }

        /* In the market order, we were able to avoid stitching back offers after every `execute` since we knew a continuous segment starting at best would be consumed. Here, we cannot do this optimisation since offers in the `targets` array may be anywhere in the book. So we stitch together offers immediately after each `execute`. */
        if (mgvData != "mgv/notExecuted") {
          sor.local = stitchOffers(
            sor.outbound_tkn,
            sor.inbound_tkn,
            sor.offer.prev(),
            sor.offer.next(),
            sor.local
          );
        }

        /* <a id="internalSnipes/liftReentrancy"></a> Now that the current snipe is over, we can lift the lock on the book. In the same operation we
        * lift the reentrancy lock, and
        * update the storage

        so we are free from out of order storage writes.
        */
        sor.local = sor.local.lock(false);
        locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;

        /* `payTakerMinusFees` sends the fee to the vault, proportional to the amount purchased, and gives the rest to the taker */
        payTakerMinusFees(mor, sor);

        /* In an inverted Mangrove, amounts have been lent by each offer's maker to the taker. We now call the taker. This is a noop in a normal Mangrove. */
        executeEnd(mor, sor);

        /* After an offer execution, we may run callbacks and increase the total penalty. As that part is common to market orders and snipes, it lives in its own `postExecute` function. */
        if (mgvData != "mgv/notExecuted") {
          postExecute(mor, sor, gasused, makerData, mgvData);
        }


        snipesGot += mor.totalGot;
        snipesGave += mor.totalGave;
      }
    }
  }}

  /* # General execution */
  /* During a market order or a snipes, offers get executed. The following code takes care of executing a single offer with parameters given by a `SingleOrder` within a larger context given by a `MultiOrder`. */

  /* ## Execute */
  /* This function will compare `sor.wants` `sor.gives` with `sor.offer.wants` and `sor.offer.gives`. If the price of the offer is low enough, an execution will be attempted (with volume limited by the offer's advertised volume).

     Summary of the meaning of the return values:
    * `gasused` is the gas consumed by the execution
    * `makerData` is the data returned after executing the offer
    * `mgvData` is an [internal Mangrove status code](#MgvOfferTaking/statusCodes).
  */
  function execute(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
    returns (
      uint gasused,
      bytes32 makerData,
      bytes32 mgvData
    )
  { unchecked {
    /* #### `Price comparison` */
    //+clear+
    /* The current offer has a price `p = offerWants ÷ offerGives` and the taker is ready to accept a price up to `p' = takerGives ÷ takerWants`. Comparing `offerWants * takerWants` and `offerGives * takerGives` tels us whether `p < p'`.
     */
    {
      uint offerWants = sor.offer.wants();
      uint offerGives = sor.offer.gives();
      uint takerWants = sor.wants;
      uint takerGives = sor.gives;
      /* <a id="MgvOfferTaking/checkPrice"></a>If the price is too high, we return early.

         Otherwise we now know we'll execute the offer. */
      if (offerWants * takerWants > offerGives * takerGives) {
        return (0, bytes32(0), "mgv/notExecuted");
      }

      /* ### Specification of value transfers:

      Let $o_w$ be `offerWants`, $o_g$ be `offerGives`, $t_w$ be `takerWants`, $t_g$ be `takerGives`, and `f ∈ {w,g}` be $w$ if `fillWants` is true, $g$ otherwise.

      Let $\textrm{got}$ be the amount that the taker will receive, and $\textrm{gave}$ be the amount that the taker will pay.

      #### Case $f = w$

      If $f = w$, let $\textrm{got} = \min(o_g,t_w)$, and let $\textrm{gave} = \left\lceil\dfrac{o_w \textrm{got}}{o_g}\right\rceil$. This is well-defined since, for live offers, $o_g > 0$.

      In plain english, we only give to the taker up to what they wanted (or what the offer has to give), and follow the offer price to determine what the taker will give.

      Since $\textrm{gave}$ is rounded up, the price might be overevaluated. Still, we cannot spend more than what the taker specified as `takerGives`. At this point [we know](#MgvOfferTaking/checkPrice) that $o_w t_w \leq o_g t_g$, so since $t_g$ is an integer we have
      
      $t_g \geq \left\lceil\dfrac{o_w t_w}{o_g}\right\rceil \geq \left\lceil\dfrac{o_w \textrm{got}}{o_g}\right\rceil = \textrm{gave}$.


      #### Case $f = g$

      If $f = g$, let $\textrm{gave} = \min(o_w,t_g)$, and $\textrm{got} = o_g$ if $o_w = 0$, $\textrm{got} = \left\lfloor\dfrac{o_g \textrm{gave}}{o_w}\right\rfloor$ otherwise.

      In plain english, we spend up to what the taker agreed to pay (or what the offer wants), and follow the offer price to determine what the taker will get. This may exceed $t_w$.

      #### Price adjustment

      Prices are rounded up to ensure maker is not drained on small amounts. It's economically unlikely, but `density` protects the taker from being drained anyway so it is better to default towards protecting the maker here.
      */

      /*
      ### Implementation

      First we check the cases $(f=w \wedge o_g < t_w)\vee(f_g \wedge o_w < t_g)$, in which case the above spec simplifies to $\textrm{got} = o_g, \textrm{gave} = o_w$.

      Otherwise the offer may be partially consumed.
      
      In the case $f=w$ we don't touch $\textrm{got}$ (which was initialized to $t_w$) and compute $\textrm{gave} = \left\lceil\dfrac{o_w t_w}{o_g}\right\rceil$. As shown above we have $\textrm{gave} \leq t_g$.

      In the case $f=g$ we don't touch $\textrm{gave}$ (which was initialized to $t_g$) and compute $\textrm{got} = o_g$ if $o_w = 0$, and $\textrm{got} = \left\lfloor\dfrac{o_g t_g}{o_w}\right\rfloor$ otherwise.
      */
      if (
        (mor.fillWants && offerGives < takerWants) ||
        (!mor.fillWants && offerWants < takerGives)
      ) {
        sor.wants = offerGives;
        sor.gives = offerWants;
      } else {
        if (mor.fillWants) {
          uint product = offerWants * takerWants;
          sor.gives =
            product /
            offerGives +
            (product % offerGives == 0 ? 0 : 1);
        } else {
          if (offerWants == 0) {
            sor.wants = offerGives;
          } else {
            sor.wants = (offerGives * takerGives) / offerWants;
          }
        }
      }
    }
    /* The flashloan is executed by call to `flashloan`. If the call reverts, it means the maker failed to send back `sor.wants` `outbound_tkn` to the taker. Notes :
     * `msg.sender` is the Mangrove itself in those calls -- all operations related to the actual caller should be done outside of this call.
     * any spurious exception due to an error in Mangrove code will be falsely blamed on the Maker, and its provision for the offer will be unfairly taken away.
     */
    (bool success, bytes memory retdata) = address(this).call(
      abi.encodeWithSelector(this.flashloan.selector, sor, mor.taker)
    );

    /* `success` is true: trade is complete */
    if (success) {
      /* In case of success, `retdata` encodes the gas used by the offer. */
      gasused = abi.decode(retdata, (uint));
      /* `mgvData` indicates trade success */
      mgvData = bytes32("mgv/tradeSuccess");
      emit OfferSuccess(
        sor.outbound_tkn,
        sor.inbound_tkn,
        sor.offerId,
        mor.taker,
        sor.wants,
        sor.gives
      );

      /* If configured to do so, the Mangrove notifies an external contract that a successful trade has taken place. */
      if (sor.global.notify()) {
        IMgvMonitor(sor.global.monitor()).notifySuccess(
          sor,
          mor.taker
        );
      }

      /* We update the totals in the multiorder based on the adjusted `sor.wants`/`sor.gives`. */
      /* overflow: sor.{wants,gives} are on 96bits, sor.total{Got,Gave} are on 256 bits. */
      mor.totalGot += sor.wants;
      mor.totalGave += sor.gives;
    } else {
      /* In case of failure, `retdata` encodes a short [status code](#MgvOfferTaking/statusCodes), the gas used by the offer, and an arbitrary 256 bits word sent by the maker.  */
      (mgvData, gasused, makerData) = innerDecode(retdata);
      /* Note that in the `if`s, the literals are bytes32 (stack values), while as revert arguments, they are strings (memory pointers). */
      if (
        mgvData == "mgv/makerRevert" ||
        mgvData == "mgv/makerAbort" ||
        mgvData == "mgv/makerTransferFail" ||
        mgvData == "mgv/makerReceiveFail"
      ) {

        emit OfferFail(
          sor.outbound_tkn,
          sor.inbound_tkn,
          sor.offerId,
          mor.taker,
          sor.wants,
          sor.gives,
          mgvData
        );

        /* If configured to do so, the Mangrove notifies an external contract that a failed trade has taken place. */
        if (sor.global.notify()) {
          IMgvMonitor(sor.global.monitor()).notifyFail(
            sor,
            mor.taker
          );
        }
        /* It is crucial that any error code which indicates an error caused by the taker triggers a revert, because functions that call `execute` consider that `mgvData` not in `["mgv/notExecuted","mgv/tradeSuccess"]` should be blamed on the maker. */
      } else if (mgvData == "mgv/notEnoughGasForMakerTrade") {
        revert("mgv/notEnoughGasForMakerTrade");
      } else if (mgvData == "mgv/takerTransferFail") {
        revert("mgv/takerTransferFail");
      } else {
        /* This code must be unreachable. **Danger**: if a well-crafted offer/maker pair can force a revert of `flashloan`, the Mangrove will be stuck. */
        revert("mgv/swapError");
      }
    }

    /* Delete the offer. The last argument indicates whether the offer should be stripped of its provision (yes if execution failed, no otherwise). We delete offers whether the amount remaining on offer is > density or not for the sake of uniformity (code is much simpler). We also expect prices to move often enough that the maker will want to update their price anyway. To simulate leaving the remaining volume in the offer, the maker can program their `makerPosthook` to `updateOffer` and put the remaining volume back in. */
    dirtyDeleteOffer(
      sor.outbound_tkn,
      sor.inbound_tkn,
      sor.offerId,
      sor.offer,
      sor.offerDetail,
      mgvData != "mgv/tradeSuccess"
    );
  }}

  /* ## flashloan (abstract) */
  /* Externally called by `execute`, flashloan lends money (from the taker to the maker, or from the maker to the taker, depending on the implementation) then calls `makerExecute` to run the maker liquidity fetching code. If `makerExecute` is unsuccessful, `flashloan` reverts (but the larger orderbook traversal will continue). 

  All `flashloan` implementations must `require(msg.sender) == address(this))`. */
  function flashloan(ML.SingleOrder calldata sor, address taker)
    external
    virtual
    returns (uint gasused);

  /* ## Maker Execute */
  /* Called by `flashloan`, `makerExecute` runs the maker code and checks that it can safely send the desired assets to the taker. */

  function makerExecute(ML.SingleOrder calldata sor)
    internal
    returns (uint gasused)
  { unchecked {
    bytes memory cd = abi.encodeWithSelector(IMaker.makerExecute.selector, sor);

    uint gasreq = sor.offerDetail.gasreq();
    address maker = sor.offerDetail.maker();
    uint oldGas = gasleft();
    /* We let the maker pay for the overhead of checking remaining gas and making the call, as well as handling the return data (constant gas since only the first 32 bytes of return data are read). So the `require` below is just an approximation: if the overhead of (`require` + cost of `CALL`) is $h$, the maker will receive at worst $\textrm{gasreq} - \frac{63h}{64}$ gas. */
    /* Note : as a possible future feature, we could stop an order when there's not enough gas left to continue processing offers. This could be done safely by checking, as soon as we start processing an offer, whether `63/64(gasleft-offer_gasbase) > gasreq`. If no, we could stop and know by induction that there is enough gas left to apply fees, stitch offers, etc for the offers already executed. */
    if (!(oldGas - oldGas / 64 >= gasreq)) {
      innerRevert([bytes32("mgv/notEnoughGasForMakerTrade"), "", ""]);
    }

    (bool callSuccess, bytes32 makerData) = controlledCall(maker, gasreq, cd);

    gasused = oldGas - gasleft();

    if (!callSuccess) {
      innerRevert([bytes32("mgv/makerRevert"), bytes32(gasused), makerData]);
    }

    /* Successful execution must have a returndata that begins with `bytes32("")`.
     */
    if (makerData != "") {
      innerRevert([bytes32("mgv/makerAbort"), bytes32(gasused), makerData]);
    }

    bool transferSuccess = transferTokenFrom(
      sor.outbound_tkn,
      maker,
      address(this),
      sor.wants
    );

    if (!transferSuccess) {
      innerRevert(
        [bytes32("mgv/makerTransferFail"), bytes32(gasused), makerData]
      );
    }
  }}

  /* ## executeEnd (abstract) */
  /* Called by `internalSnipes` and `internalMarketOrder`, `executeEnd` may run implementation-specific code after all makers have been called once. In [`InvertedMangrove`](#InvertedMangrove), the function calls the taker once so they can act on their flashloan. In [`Mangrove`], it does nothing. */
  function executeEnd(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
    virtual;

  /* ## Post execute */
  /* At this point, we know `mgvData != "mgv/notExecuted"`. After executing an offer (whether in a market order or in snipes), we
     1. Call the maker's posthook and sum the total gas used.
     2. If offer failed: sum total penalty due to taker and give remainder to maker.
   */
  function postExecute(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    uint gasused,
    bytes32 makerData,
    bytes32 mgvData
  ) internal { unchecked {
    if (mgvData == "mgv/tradeSuccess") {
      beforePosthook(sor);
    }

    uint gasreq = sor.offerDetail.gasreq();

    /* We are about to call back the maker, giving it its unused gas (`gasreq - gasused`). Since the gas used so far may exceed `gasreq`, we prevent underflow in the subtraction below by bounding `gasused` above with `gasreq`. We could have decided not to call back the maker at all when there is no gas left, but we do it for uniformity. */
    if (gasused > gasreq) {
      gasused = gasreq;
    }

    gasused =
      gasused +
      makerPosthook(sor, gasreq - gasused, makerData, mgvData);

    if (mgvData != "mgv/tradeSuccess") {
      mor.totalPenalty += applyPenalty(sor, gasused);
    }
  }}

  /* ## beforePosthook (abstract) */
  /* Called by `makerPosthook`, this function can run implementation-specific code before calling the maker has been called a second time. In [`InvertedMangrove`](#InvertedMangrove), all makers are called once so the taker gets all of its money in one shot. Then makers are traversed again and the money is sent back to each taker using `beforePosthook`. In [`Mangrove`](#Mangrove), `beforePosthook` does nothing. */

  function beforePosthook(ML.SingleOrder memory sor) internal virtual;

  /* ## Maker Posthook */
  function makerPosthook(
    ML.SingleOrder memory sor,
    uint gasLeft,
    bytes32 makerData,
    bytes32 mgvData
  ) internal returns (uint gasused) { unchecked {
    /* At this point, mgvData can only be `"mgv/tradeSuccess"`, `"mgv/makerAbort"`, `"mgv/makerRevert"`, `"mgv/makerTransferFail"` or `"mgv/makerReceiveFail"` */
    bytes memory cd = abi.encodeWithSelector(
      IMaker.makerPosthook.selector,
      sor,
      ML.OrderResult({makerData: makerData, mgvData: mgvData})
    );

    address maker = sor.offerDetail.maker();

    uint oldGas = gasleft();
    /* We let the maker pay for the overhead of checking remaining gas and making the call. So the `require` below is just an approximation: if the overhead of (`require` + cost of `CALL`) is $h$, the maker will receive at worst $\textrm{gasreq} - \frac{63h}{64}$ gas. */
    if (!(oldGas - oldGas / 64 >= gasLeft)) {
      revert("mgv/notEnoughGasForMakerPosthook");
    }

    (bool callSuccess, ) = controlledCall(maker, gasLeft, cd);

    gasused = oldGas - gasleft();

    if (!callSuccess) {
      emit PosthookFail(sor.outbound_tkn, sor.inbound_tkn, sor.offerId);
    }
  }}

  /* ## `controlledCall` */
  /* Calls an external function with controlled gas expense. A direct call of the form `(,bytes memory retdata) = maker.call{gas}(selector,...args)` enables a griefing attack: the maker uses half its gas to write in its memory, then reverts with that memory segment as argument. After a low-level call, solidity automaticaly copies `returndatasize` bytes of `returndata` into memory. So the total gas consumed to execute a failing offer could exceed `gasreq + offer_gasbase` where `n` is the number of failing offers. This yul call only retrieves the first 32 bytes of the maker's `returndata`. */
  function controlledCall(
    address callee,
    uint gasreq,
    bytes memory cd
  ) internal returns (bool success, bytes32 data) { unchecked {
    bytes32[1] memory retdata;

    assembly {
      success := call(gasreq, callee, 0, add(cd, 32), mload(cd), retdata, 32)
    }

    data = retdata[0];
  }}

  /* # Penalties */
  /* Offers are just promises. They can fail. Penalty provisioning discourages from failing too much: we ask makers to provision more ETH than the expected gas cost of executing their offer and penalize them accoridng to wasted gas.

     Under normal circumstances, we should expect to see bots with a profit expectation dry-running offers locally and executing `snipe` on failing offers, collecting the penalty. The result should be a mostly clean book for actual takers (i.e. a book with only successful offers).

     **Incentive issue**: if the gas price increases enough after an offer has been created, there may not be an immediately profitable way to remove the fake offers. In that case, we count on 3 factors to keep the book clean:
     1. Gas price eventually comes down.
     2. Other market makers want to keep the Mangrove attractive and maintain their offer flow.
     3. Mangrove governance (who may collect a fee) wants to keep the Mangrove attractive and maximize exchange volume. */

  //+clear+
  /* After an offer failed, part of its provision is given back to the maker and the rest is stored to be sent to the taker after the entire order completes. In `applyPenalty`, we _only_ credit the maker with its excess provision. So it looks like the maker is gaining something. In fact they're just getting back a fraction of what they provisioned earlier. */
  /*
     Penalty application summary:

   * If the transaction was a success, we entirely refund the maker and send nothing to the taker.
   * Otherwise, the maker loses the cost of `gasused + offer_gasbase` gas. The gas price is estimated by `gasprice`.
   * To create the offer, the maker had to provision for `gasreq + offer_gasbase` gas at a price of `offerDetail.gasprice`.
   * We do not consider the tx.gasprice.
   * `offerDetail.gasbase` and `offerDetail.gasprice` are the values of the Mangrove parameters `config.offer_gasbase` and `config.gasprice` when the offer was created. Without caching those values, the provision set aside could end up insufficient to reimburse the maker (or to retribute the taker).
   */
  function applyPenalty(
    ML.SingleOrder memory sor,
    uint gasused
  ) internal returns (uint) { unchecked {
    uint gasreq = sor.offerDetail.gasreq();

    uint provision = 10**9 *
      sor.offerDetail.gasprice() * 
      (gasreq + sor.offerDetail.offer_gasbase());

    /* We set `gasused = min(gasused,gasreq)` since `gasreq < gasused` is possible e.g. with `gasreq = 0` (all calls consume nonzero gas). */
    if (gasused > gasreq) {
      gasused = gasreq;
    }

    /* As an invariant, `applyPenalty` is only called when `mgvData` is not in `["mgv/notExecuted","mgv/tradeSuccess"]` */
    uint penalty = 10**9 *
      sor.global.gasprice() *
      (gasused +
        sor.local.offer_gasbase());

    if (penalty > provision) {
      penalty = provision;
    }

    /* Here we write to storage the new maker balance. This occurs _after_ possible reentrant calls. How do we know we're not crediting twice the same amounts? Because the `offer`'s provision was set to 0 in storage (through `dirtyDeleteOffer`) before the reentrant calls. In this function, we are working with cached copies of the offer as it was before it was consumed. */
    creditWei(sor.offerDetail.maker(), provision - penalty);

    return penalty;
  }}

  function sendPenalty(uint amount) internal { unchecked {
    if (amount > 0) {
      (bool noRevert, ) = msg.sender.call{value: amount}("");
      require(noRevert, "mgv/sendPenaltyReverted");
    }
  }}

  /* Post-trade, `payTakerMinusFees` sends what's due to the taker and the rest (the fees) to the vault. Routing through the Mangrove like that also deals with blacklisting issues (separates the maker-blacklisted and the taker-blacklisted cases). */
  function payTakerMinusFees(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
  { unchecked {
    /* Should be statically provable that the 2 transfers below cannot return false under well-behaved ERC20s and a non-blacklisted, non-0 target. */

    uint concreteFee = (mor.totalGot * sor.local.fee()) / 10_000;
    if (concreteFee > 0) {
      mor.totalGot -= concreteFee;
      require(
        transferToken(sor.outbound_tkn, vault, concreteFee),
        "mgv/feeTransferFail"
      );
    }
    if (mor.totalGot > 0) {
      require(
        transferToken(sor.outbound_tkn, mor.taker, mor.totalGot),
        "mgv/MgvFailToPayTaker"
      );
    }
  }}

  /* # Misc. functions */

  /* Regular solidity reverts prepend the string argument with a [function signature](https://docs.soliditylang.org/en/v0.7.6/control-structures.html#revert). Since we wish to transfer data through a revert, the `innerRevert` function does a low-level revert with only the required data. `innerCode` decodes this data. */
  function innerDecode(bytes memory data)
    internal
    pure
    returns (
      bytes32 mgvData,
      uint gasused,
      bytes32 makerData
    )
  { unchecked {
    /* The `data` pointer is of the form `[mgvData,gasused,makerData]` where each array element is contiguous and has size 256 bits. */
    assembly {
      mgvData := mload(add(data, 32))
      gasused := mload(add(data, 64))
      makerData := mload(add(data, 96))
    }
  }}

  /* <a id="MgvOfferTaking/innerRevert"></a>`innerRevert` reverts a raw triple of values to be interpreted by `innerDecode`.    */
  function innerRevert(bytes32[3] memory data) internal pure { unchecked {
    assembly {
      revert(data, 96)
    }
  }}

  /* `transferTokenFrom` is adapted from [existing code](https://soliditydeveloper.com/safe-erc20) and in particular avoids the
  "no return value" bug. It never throws and returns true iff the transfer was successful according to `tokenAddress`.

    Note that any spurious exception due to an error in Mangrove code will be falsely blamed on `from`.
  */
  function transferTokenFrom(
    address tokenAddress,
    address from,
    address to,
    uint value
  ) internal returns (bool) { unchecked {
    bytes memory cd = abi.encodeWithSelector(
      IERC20.transferFrom.selector,
      from,
      to,
      value
    );
    (bool noRevert, bytes memory data) = tokenAddress.call(cd);
    return (noRevert && (data.length == 0 || abi.decode(data, (bool))));
  }}

  function transferToken(
    address tokenAddress,
    address to,
    uint value
  ) internal returns (bool) { unchecked {
    bytes memory cd = abi.encodeWithSelector(
      IERC20.transfer.selector,
      to,
      value
    );
    (bool noRevert, bytes memory data) = tokenAddress.call(cd);
    return (noRevert && (data.length == 0 || abi.decode(data, (bool))));
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvOfferTakingWithPermit.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;
pragma abicoder v2;
import {HasMgvEvents} from "./MgvLib.sol";

import {MgvOfferTaking} from "./MgvOfferTaking.sol";

abstract contract MgvOfferTakingWithPermit is MgvOfferTaking {
  /* Takers may provide allowances on specific pairs, so other addresses can execute orders in their name. Allowance may be set using the usual `approve` function, or through an [EIP712](https://eips.ethereum.org/EIPS/eip-712) `permit`.

  The mapping is `outbound_tkn => inbound_tkn => owner => spender => allowance` */
  mapping(address => mapping(address => mapping(address => mapping(address => uint))))
    public allowances;
  /* Storing nonces avoids replay attacks. */
  mapping(address => uint) public nonces;
  /* Following [EIP712](https://eips.ethereum.org/EIPS/eip-712), structured data signing has `keccak256("Permit(address outbound_tkn,address inbound_tkn,address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")` in its prefix. */
  bytes32 public constant PERMIT_TYPEHASH =
    0xb7bf278e51ab1478b10530c0300f911d9ed3562fc93ab5e6593368fe23c077a2;
  /* Initialized in the constructor, `DOMAIN_SEPARATOR` avoids cross-application permit reuse. */
  bytes32 public immutable DOMAIN_SEPARATOR;

  constructor(string memory contractName) {
    /* Initialize [EIP712](https://eips.ethereum.org/EIPS/eip-712) `DOMAIN_SEPARATOR`. */
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes(contractName)),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
    );
  }

  /* # Delegation public functions */

  /* Adapted from [Uniswap v2 contract](https://github.com/Uniswap/uniswap-v2-core/blob/55ae25109b7918565867e5c39f1e84b7edd19b2a/contracts/UniswapV2ERC20.sol#L81) */
  function permit(
    address outbound_tkn,
    address inbound_tkn,
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    unchecked {
      require(deadline >= block.timestamp, "mgv/permit/expired");

      uint nonce = nonces[owner]++;
      bytes32 digest = keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(
            abi.encode(
              PERMIT_TYPEHASH,
              outbound_tkn,
              inbound_tkn,
              owner,
              spender,
              value,
              nonce,
              deadline
            )
          )
        )
      );
      address recoveredAddress = ecrecover(digest, v, r, s);
      require(
        recoveredAddress != address(0) && recoveredAddress == owner,
        "mgv/permit/invalidSignature"
      );

      allowances[outbound_tkn][inbound_tkn][owner][spender] = value;
      emit Approval(outbound_tkn, inbound_tkn, owner, spender, value);
    }
  }

  function approve(
    address outbound_tkn,
    address inbound_tkn,
    address spender,
    uint value
  ) external returns (bool) {
    unchecked {
      allowances[outbound_tkn][inbound_tkn][msg.sender][spender] = value;
      emit Approval(outbound_tkn, inbound_tkn, msg.sender, spender, value);
      return true;
    }
  }

  /* The delegate version of `marketOrder` is `marketOrderFor`, which takes a `taker` address as additional argument. Penalties incurred by failed offers will still be sent to `msg.sender`, but exchanged amounts will be transferred from and to the `taker`. If the `msg.sender`'s allowance for the given `outbound_tkn`,`inbound_tkn` and `taker` are strictly less than the total amount eventually spent by `taker`, the call will fail. */

  /* *Note:* `marketOrderFor` and `snipesFor` may emit ERC20 `Transfer` events of value 0 from `taker`, but that's already the case with common ERC20 implementations. */
  function marketOrderFor(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint takerGot,
      uint takerGave,
      uint bounty
    )
  {
    unchecked {
      (takerGot, takerGave, bounty) = generalMarketOrder(
        outbound_tkn,
        inbound_tkn,
        takerWants,
        takerGives,
        fillWants,
        taker
      );
      /* The sender's allowance is verified after the order complete so that `takerGave` rather than `takerGives` is checked against the allowance. The former may be lower. */
      deductSenderAllowance(outbound_tkn, inbound_tkn, taker, takerGave);
    }
  }

  /* The delegate version of `snipes` is `snipesFor`, which takes a `taker` address as additional argument. */
  function snipesFor(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint successes,
      uint takerGot,
      uint takerGave,
      uint bounty
    )
  {
    unchecked {
      (successes, takerGot, takerGave, bounty) = generalSnipes(
        outbound_tkn,
        inbound_tkn,
        targets,
        fillWants,
        taker
      );
      /* The sender's allowance is verified after the order complete so that the actual amounts are checked against the allowance, instead of the declared `takerGives`. The former may be lower.
    
    An immediate consequence is that any funds availale to Mangrove through `approve` can be used to clean offers. After a `snipesFor` where all offers have failed, all token transfers have been reverted, so `takerGave=0` and the check will succeed -- but the sender will still have received the bounty of the failing offers. */
      deductSenderAllowance(outbound_tkn, inbound_tkn, taker, takerGave);
    }
  }

  /* # Misc. low-level functions */

  /* Used by `*For` functions, its both checks that `msg.sender` was allowed to use the taker's funds, and decreases the former's allowance. */
  function deductSenderAllowance(
    address outbound_tkn,
    address inbound_tkn,
    address owner,
    uint amount
  ) internal {
    unchecked {
      uint allowed = allowances[outbound_tkn][inbound_tkn][owner][msg.sender];
      require(allowed >= amount, "mgv/lowAllowance");
      allowances[outbound_tkn][inbound_tkn][owner][msg.sender] =
        allowed -
        amount;

      emit Approval(
        outbound_tkn,
        inbound_tkn,
        owner,
        msg.sender,
        allowed - amount
      );
    }
  }
}

pragma solidity ^0.8.10;

// SPDX-License-Identifier: Unlicense

// MgvPack.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

// fields are of the form [name,bits,type]

// Can't put all structs under a 'Structs' library due to bad variable shadowing rules in Solidity
// (would generate lots of spurious warnings about a nameclash between Structs.Offer and library Offer for instance)
// struct_defs are of the form [name,obj]
struct OfferStruct {
  uint prev;
  uint next;
  uint wants;
  uint gives;
}
struct OfferDetailStruct {
  address maker;
  uint gasreq;
  uint offer_gasbase;
  uint gasprice;
}
struct GlobalStruct {
  address monitor;
  bool useOracle;
  bool notify;
  uint gasprice;
  uint gasmax;
  bool dead;
}
struct LocalStruct {
  bool active;
  uint fee;
  uint density;
  uint offer_gasbase;
  bool lock;
  uint best;
  uint last;
}

library Offer {
  //some type safety for each struct
  type t is uint;

  uint constant prev_bits  = 32;
  uint constant next_bits  = 32;
  uint constant wants_bits = 96;
  uint constant gives_bits = 96;

  uint constant prev_before  = 0;
  uint constant next_before  = prev_before  + prev_bits ;
  uint constant wants_before = next_before  + next_bits ;
  uint constant gives_before = wants_before + wants_bits;

  uint constant prev_mask  = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant next_mask  = 0xffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant wants_mask = 0xffffffffffffffff000000000000000000000000ffffffffffffffffffffffff;
  uint constant gives_mask = 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000;

  function to_struct(t __packed) internal pure returns (OfferStruct memory __s) { unchecked {
    __s.prev = (t.unwrap(__packed) << prev_before) >> (256-prev_bits);
    __s.next = (t.unwrap(__packed) << next_before) >> (256-next_bits);
    __s.wants = (t.unwrap(__packed) << wants_before) >> (256-wants_bits);
    __s.gives = (t.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}

  function t_of_struct(OfferStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.prev, __s.next, __s.wants, __s.gives);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(uint __prev, uint __next, uint __wants, uint __gives) internal pure returns (t) { unchecked {
    return t.wrap(((((0
                  | ((__prev << (256-prev_bits)) >> prev_before))
                  | ((__next << (256-next_bits)) >> next_before))
                  | ((__wants << (256-wants_bits)) >> wants_before))
                  | ((__gives << (256-gives_bits)) >> gives_before)));
  }}

  function unpack(t __packed) internal pure returns (uint __prev, uint __next, uint __wants, uint __gives) { unchecked {
    __prev = (t.unwrap(__packed) << prev_before) >> (256-prev_bits);
    __next = (t.unwrap(__packed) << next_before) >> (256-next_bits);
    __wants = (t.unwrap(__packed) << wants_before) >> (256-wants_bits);
    __gives = (t.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}

  function prev(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << prev_before) >> (256-prev_bits);
  }}
  function prev(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & prev_mask)
                  | ((val << (256-prev_bits) >> prev_before)));
  }}
  function next(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << next_before) >> (256-next_bits);
  }}
  function next(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & next_mask)
                  | ((val << (256-next_bits) >> next_before)));
  }}
  function wants(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << wants_before) >> (256-wants_bits);
  }}
  function wants(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & wants_mask)
                  | ((val << (256-wants_bits) >> wants_before)));
  }}
  function gives(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}
  function gives(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gives_mask)
                  | ((val << (256-gives_bits) >> gives_before)));
  }}
}

library OfferDetail {
  //some type safety for each struct
  type t is uint;

  uint constant maker_bits         = 160;
  uint constant gasreq_bits        = 24;
  uint constant offer_gasbase_bits = 24;
  uint constant gasprice_bits      = 16;

  uint constant maker_before         = 0;
  uint constant gasreq_before        = maker_before         + maker_bits        ;
  uint constant offer_gasbase_before = gasreq_before        + gasreq_bits       ;
  uint constant gasprice_before      = offer_gasbase_before + offer_gasbase_bits;

  uint constant maker_mask         = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
  uint constant gasreq_mask        = 0xffffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
  uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
  uint constant gasprice_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffff;

  function to_struct(t __packed) internal pure returns (OfferDetailStruct memory __s) { unchecked {
    __s.maker = address(uint160((t.unwrap(__packed) << maker_before) >> (256-maker_bits)));
    __s.gasreq = (t.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
    __s.offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __s.gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}

  function t_of_struct(OfferDetailStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.maker, __s.gasreq, __s.offer_gasbase, __s.gasprice);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) internal pure returns (t) { unchecked {
    return t.wrap(((((0
                  | ((uint(uint160(__maker)) << (256-maker_bits)) >> maker_before))
                  | ((__gasreq << (256-gasreq_bits)) >> gasreq_before))
                  | ((__offer_gasbase << (256-offer_gasbase_bits)) >> offer_gasbase_before))
                  | ((__gasprice << (256-gasprice_bits)) >> gasprice_before)));
  }}

  function unpack(t __packed) internal pure returns (address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) { unchecked {
    __maker = address(uint160((t.unwrap(__packed) << maker_before) >> (256-maker_bits)));
    __gasreq = (t.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
    __offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}

  function maker(t __packed) internal pure returns(address) { unchecked {
    return address(uint160((t.unwrap(__packed) << maker_before) >> (256-maker_bits)));
  }}
  function maker(t __packed,address val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & maker_mask)
                  | ((uint(uint160(val)) << (256-maker_bits) >> maker_before)));
  }}
  function gasreq(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
  }}
  function gasreq(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasreq_mask)
                  | ((val << (256-gasreq_bits) >> gasreq_before)));
  }}
  function offer_gasbase(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
  }}
  function offer_gasbase(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & offer_gasbase_mask)
                  | ((val << (256-offer_gasbase_bits) >> offer_gasbase_before)));
  }}
  function gasprice(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}
  function gasprice(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasprice_mask)
                  | ((val << (256-gasprice_bits) >> gasprice_before)));
  }}
}

library Global {
  //some type safety for each struct
  type t is uint;

  uint constant monitor_bits   = 160;
  uint constant useOracle_bits = 8;
  uint constant notify_bits    = 8;
  uint constant gasprice_bits  = 16;
  uint constant gasmax_bits    = 24;
  uint constant dead_bits      = 8;

  uint constant monitor_before   = 0;
  uint constant useOracle_before = monitor_before   + monitor_bits  ;
  uint constant notify_before    = useOracle_before + useOracle_bits;
  uint constant gasprice_before  = notify_before    + notify_bits   ;
  uint constant gasmax_before    = gasprice_before  + gasprice_bits ;
  uint constant dead_before      = gasmax_before    + gasmax_bits   ;

  uint constant monitor_mask   = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
  uint constant useOracle_mask = 0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
  uint constant notify_mask    = 0xffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffff;
  uint constant gasprice_mask  = 0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff;
  uint constant gasmax_mask    = 0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffff;
  uint constant dead_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffff;

  function to_struct(t __packed) internal pure returns (GlobalStruct memory __s) { unchecked {
    __s.monitor = address(uint160((t.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
    __s.useOracle = (((t.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
    __s.notify = (((t.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
    __s.gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
    __s.gasmax = (t.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
    __s.dead = (((t.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}

  function t_of_struct(GlobalStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.monitor, __s.useOracle, __s.notify, __s.gasprice, __s.gasmax, __s.dead);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) internal pure returns (t) { unchecked {
    return t.wrap(((((((0
                  | ((uint(uint160(__monitor)) << (256-monitor_bits)) >> monitor_before))
                  | ((uint_of_bool(__useOracle) << (256-useOracle_bits)) >> useOracle_before))
                  | ((uint_of_bool(__notify) << (256-notify_bits)) >> notify_before))
                  | ((__gasprice << (256-gasprice_bits)) >> gasprice_before))
                  | ((__gasmax << (256-gasmax_bits)) >> gasmax_before))
                  | ((uint_of_bool(__dead) << (256-dead_bits)) >> dead_before)));
  }}

  function unpack(t __packed) internal pure returns (address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) { unchecked {
    __monitor = address(uint160((t.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
    __useOracle = (((t.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
    __notify = (((t.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
    __gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
    __gasmax = (t.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
    __dead = (((t.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}

  function monitor(t __packed) internal pure returns(address) { unchecked {
    return address(uint160((t.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
  }}
  function monitor(t __packed,address val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & monitor_mask)
                  | ((uint(uint160(val)) << (256-monitor_bits) >> monitor_before)));
  }}
  function useOracle(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
  }}
  function useOracle(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & useOracle_mask)
                  | ((uint_of_bool(val) << (256-useOracle_bits) >> useOracle_before)));
  }}
  function notify(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
  }}
  function notify(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & notify_mask)
                  | ((uint_of_bool(val) << (256-notify_bits) >> notify_before)));
  }}
  function gasprice(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}
  function gasprice(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasprice_mask)
                  | ((val << (256-gasprice_bits) >> gasprice_before)));
  }}
  function gasmax(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
  }}
  function gasmax(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasmax_mask)
                  | ((val << (256-gasmax_bits) >> gasmax_before)));
  }}
  function dead(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}
  function dead(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & dead_mask)
                  | ((uint_of_bool(val) << (256-dead_bits) >> dead_before)));
  }}
}

library Local {
  //some type safety for each struct
  type t is uint;

  uint constant active_bits        = 8;
  uint constant fee_bits           = 16;
  uint constant density_bits       = 112;
  uint constant offer_gasbase_bits = 24;
  uint constant lock_bits          = 8;
  uint constant best_bits          = 32;
  uint constant last_bits          = 32;

  uint constant active_before        = 0;
  uint constant fee_before           = active_before        + active_bits       ;
  uint constant density_before       = fee_before           + fee_bits          ;
  uint constant offer_gasbase_before = density_before       + density_bits      ;
  uint constant lock_before          = offer_gasbase_before + offer_gasbase_bits;
  uint constant best_before          = lock_before          + lock_bits         ;
  uint constant last_before          = best_before          + best_bits         ;

  uint constant active_mask        = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant fee_mask           = 0xff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint constant density_mask       = 0xffffff0000000000000000000000000000ffffffffffffffffffffffffffffff;
  uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff;
  uint constant lock_mask          = 0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
  uint constant best_mask          = 0xffffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffff;
  uint constant last_mask          = 0xffffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffff;

  function to_struct(t __packed) internal pure returns (LocalStruct memory __s) { unchecked {
    __s.active = (((t.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
    __s.fee = (t.unwrap(__packed) << fee_before) >> (256-fee_bits);
    __s.density = (t.unwrap(__packed) << density_before) >> (256-density_bits);
    __s.offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __s.lock = (((t.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
    __s.best = (t.unwrap(__packed) << best_before) >> (256-best_bits);
    __s.last = (t.unwrap(__packed) << last_before) >> (256-last_bits);
  }}

  function t_of_struct(LocalStruct memory __s) internal pure returns (t) { unchecked {
    return pack(__s.active, __s.fee, __s.density, __s.offer_gasbase, __s.lock, __s.best, __s.last);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function pack(bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) internal pure returns (t) { unchecked {
    return t.wrap((((((((0
                  | ((uint_of_bool(__active) << (256-active_bits)) >> active_before))
                  | ((__fee << (256-fee_bits)) >> fee_before))
                  | ((__density << (256-density_bits)) >> density_before))
                  | ((__offer_gasbase << (256-offer_gasbase_bits)) >> offer_gasbase_before))
                  | ((uint_of_bool(__lock) << (256-lock_bits)) >> lock_before))
                  | ((__best << (256-best_bits)) >> best_before))
                  | ((__last << (256-last_bits)) >> last_before)));
  }}

  function unpack(t __packed) internal pure returns (bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) { unchecked {
    __active = (((t.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
    __fee = (t.unwrap(__packed) << fee_before) >> (256-fee_bits);
    __density = (t.unwrap(__packed) << density_before) >> (256-density_bits);
    __offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __lock = (((t.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
    __best = (t.unwrap(__packed) << best_before) >> (256-best_bits);
    __last = (t.unwrap(__packed) << last_before) >> (256-last_bits);
  }}

  function active(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
  }}
  function active(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & active_mask)
                  | ((uint_of_bool(val) << (256-active_bits) >> active_before)));
  }}
  function fee(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << fee_before) >> (256-fee_bits);
  }}
  function fee(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & fee_mask)
                  | ((val << (256-fee_bits) >> fee_before)));
  }}
  function density(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << density_before) >> (256-density_bits);
  }}
  function density(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & density_mask)
                  | ((val << (256-density_bits) >> density_before)));
  }}
  function offer_gasbase(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
  }}
  function offer_gasbase(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & offer_gasbase_mask)
                  | ((val << (256-offer_gasbase_bits) >> offer_gasbase_before)));
  }}
  function lock(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
  }}
  function lock(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & lock_mask)
                  | ((uint_of_bool(val) << (256-lock_bits) >> lock_before)));
  }}
  function best(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << best_before) >> (256-best_bits);
  }}
  function best(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & best_mask)
                  | ((val << (256-best_bits) >> best_before)));
  }}
  function last(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << last_before) >> (256-last_bits);
  }}
  function last(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & last_mask)
                  | ((val << (256-last_bits) >> last_before)));
  }}
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvRoot.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* `MgvRoot` and its descendants describe an orderbook-based exchange ("the Mangrove") where market makers *do not have to provision their offer*. See `structs.js` for a longer introduction. In a nutshell: each offer created by a maker specifies an address (`maker`) to call upon offer execution by a taker. In the normal mode of operation, the Mangrove transfers the amount to be paid by the taker to the maker, calls the maker, attempts to transfer the amount promised by the maker to the taker, and reverts if it cannot.

   There is one Mangrove contract that manages all tradeable pairs. This reduces deployment costs for new pairs and lets market makers have all their provision for all pairs in the same place.

   The interaction map between the different actors is as follows:
   <img src="./contactMap.png" width="190%"></img>

   The sequence diagram of a market order is as follows:
   <img src="./sequenceChart.png" width="190%"></img>

   There is a secondary mode of operation in which the _maker_ flashloans the sold amount to the taker.

   The Mangrove contract is `abstract` and accomodates both modes. Two contracts, `Mangrove` and `InvertedMangrove` inherit from it, one per mode of operation.

   The contract structure is as follows:
   <img src="./modular_mangrove.svg" width="180%"> </img>
 */

pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, HasMgvEvents, IMgvMonitor, P} from "./MgvLib.sol";

/* `MgvRoot` contains state variables used everywhere in the operation of the Mangrove and their related function. */
contract MgvRoot is HasMgvEvents {
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;


  /* # State variables */
  //+clear+
  /* The `vault` address. If a pair has fees >0, those fees are sent to the vault. */
  address public vault;

  /* Global mgv configuration, encoded in a 256 bits word. The information encoded is detailed in [`structs.js`](#structs.js). */
  P.Global.t internal internal_global;
  /* Configuration mapping for each token pair of the form `outbound_tkn => inbound_tkn => P.Local.t`. The structure of each `P.Local.t` value is detailed in [`structs.js`](#structs.js). It fits in one word. */
  mapping(address => mapping(address => P.Local.t)) internal locals;

  /* Checking the size of `density` is necessary to prevent overflow when `density` is used in calculations. */
  function checkDensity(uint density) internal pure returns (bool) { unchecked {
    return uint112(density) == density;
  }}

  /* Checking the size of `gasprice` is necessary to prevent a) data loss when `gasprice` is copied to an `OfferDetail` struct, and b) overflow when `gasprice` is used in calculations. */
  function checkGasprice(uint gasprice) internal pure returns (bool) { unchecked {
    return uint16(gasprice) == gasprice;
  }}

  /* # Configuration Reads */
  /* Reading the configuration for a pair involves reading the config global to all pairs and the local one. In addition, a global parameter (`gasprice`) and a local one (`density`) may be read from the oracle. */
  function config(address outbound_tkn, address inbound_tkn)
    public
    view
    returns (P.Global.t _global, P.Local.t _local)
  { unchecked {
    _global = internal_global;
    _local = locals[outbound_tkn][inbound_tkn];
    if (_global.useOracle()) {
      (uint gasprice, uint density) = IMgvMonitor(_global.monitor())
        .read(outbound_tkn, inbound_tkn);
      if (checkGasprice(gasprice)) {
        _global = _global.gasprice(gasprice);
      }
      if (checkDensity(density)) {
        _local = _local.density(density);
      }
    }
  }}

  /* Returns the configuration in an ABI-compatible struct. Should not be called internally, would be a huge memory copying waste. Use `config` instead. */
  function configInfo(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (P.GlobalStruct memory global, P.LocalStruct memory local)
  { unchecked {
    (P.Global.t _global, P.Local.t _local) = config(outbound_tkn, inbound_tkn);
    global = _global.to_struct();
    local = _local.to_struct();
  }}

  /* Convenience function to check whether given pair is locked */
  function locked(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (bool)
  {
    P.Local.t local = locals[outbound_tkn][inbound_tkn];
    return local.lock();
  }

  /*
  # Gatekeeping

  Gatekeeping functions are safety checks called in various places.
  */

  /* `unlockedMarketOnly` protects modifying the market while an order is in progress. Since external contracts are called during orders, allowing reentrancy would, for instance, let a market maker replace offers currently on the book with worse ones. Note that the external contracts _will_ be called again after the order is complete, this time without any lock on the market.  */
  function unlockedMarketOnly(P.Local.t local) internal pure {
    require(!local.lock(), "mgv/reentrancyLocked");
  }

  /* <a id="Mangrove/definition/liveMgvOnly"></a>
     In case of emergency, the Mangrove can be `kill`ed. It cannot be resurrected. When a Mangrove is dead, the following operations are disabled :
       * Executing an offer
       * Sending ETH to the Mangrove the normal way. Usual [shenanigans](https://medium.com/@alexsherbuck/two-ways-to-force-ether-into-a-contract-1543c1311c56) are possible.
       * Creating a new offer
   */
  function liveMgvOnly(P.Global.t _global) internal pure {
    require(!_global.dead(), "mgv/dead");
  }

  /* When the Mangrove is deployed, all pairs are inactive by default (since `locals[outbound_tkn][inbound_tkn]` is 0 by default). Offers on inactive pairs cannot be taken or created. They can be updated and retracted. */
  function activeMarketOnly(P.Global.t _global, P.Local.t _local) internal pure {
    liveMgvOnly(_global);
    require(_local.active(), "mgv/inactive");
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../../MgvLib.sol";
import "../lib/AccessControlled.sol";
import "../lib/Exponential.sol";
import "../lib/consolerr/consolerr.sol";
import "../interfaces/IOfferLogic.sol";
import "../../Mangrove.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract MangroveOffer is AccessControlled, IOfferLogic, Exponential {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;
  using P.Global for P.Global.t;
  using P.Local for P.Local.t;

  bytes32 immutable RENEGED = "MangroveOffer/reneged";
  bytes32 immutable PUTFAILURE = "MangroveOffer/putFailure";
  bytes32 immutable OUTOFLIQUIDITY = "MangroveOffer/outOfLiquidity";

  Mangrove public immutable MGV; // Address of the deployed Mangrove contract

  modifier mgvOrAdmin() {
    require(
      msg.sender == admin || msg.sender == address(MGV),
      "AccessControlled/Invalid"
    );
    _;
  }
  // default values
  uint public override OFR_GASREQ = 100_000;

  receive() external payable virtual {}

  constructor(address payable _mgv) {
    MGV = Mangrove(_mgv);
  }

  function setGasreq(uint gasreq) public override mgvOrAdmin {
    require(uint24(gasreq) == gasreq, "MangroveOffer/gasreq/overflow");
    OFR_GASREQ = gasreq;
  }

  function _transferToken(
    address token,
    address recipient,
    uint amount
  ) internal returns (bool success) {
    success = IERC20(token).transfer(recipient, amount);
  }

  // get back any ETH that might linger in the contract
  function transferETH(address recipient, uint amount)
    external
    onlyAdmin
    returns (bool success)
  {
    (success, ) = recipient.call{value: amount}("");
  }

  /// trader needs to approve Mangrove to let it perform outbound token transfer at the end of the `makerExecute` function
  function _approveMangrove(address outbound_tkn, uint amount) internal {
    require(
      IERC20(outbound_tkn).approve(address(MGV), amount),
      "mgvOffer/approve/Fail"
    );
  }

  /// withdraws ETH from the bounty vault of the Mangrove.
  /// NB: `Mangrove.fund` function need not be called by `this` so is not included here.
  function _withdrawFromMangrove(address receiver, uint amount)
    internal
    returns (bool noRevert)
  {
    require(MGV.withdraw(amount), "MangroveOffer/withdraw/transferFail");
    (noRevert, ) = receiver.call{value: amount}("");
  }

  // returns missing provision to repost `offerId` at given `gasreq` and `gasprice`
  // if `offerId` is not in the offerList, will simply return how much is needed to post
  function _getMissingProvision(
    uint balance, // offer owner balance on Mangrove
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq, // give > type(uint24).max to use `this.OFR_GASREQ()`
    uint gasprice, // give 0 to use Mangrove's gasprice
    uint offerId // set this to 0 if one is not reposting an offer
  ) internal view returns (uint) {
    (P.Global.t globalData, P.Local.t localData) = MGV.config(
      outbound_tkn,
      inbound_tkn
    );
    P.OfferDetail.t offerDetailData = MGV.offerDetails(
      outbound_tkn,
      inbound_tkn,
      offerId
    );
    uint _gp;
    if (globalData.gasprice() > gasprice) {
      _gp = globalData.gasprice();
    } else {
      _gp = gasprice;
    }
    if (gasreq > type(uint24).max) {
      gasreq = OFR_GASREQ;
    }
    uint bounty = (gasreq + localData.offer_gasbase()) * _gp * 10**9; // in WEI
    // if `offerId` is not in the OfferList, all returned values will be 0
    uint currentProvisionLocked = (offerDetailData.gasreq() +
      offerDetailData.offer_gasbase()) *
      offerDetailData.gasprice() *
      10**9;
    uint currentProvision = currentProvisionLocked + balance;
    return (currentProvision >= bounty ? 0 : bounty - currentProvision);
  }

  function giveAtDensity(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq
  ) public view returns (uint) {
    (, P.Local.t localData) = MGV.config(outbound_tkn, inbound_tkn);
    gasreq = gasreq > type(uint24).max ? OFR_GASREQ : gasreq;
    return (gasreq + localData.offer_gasbase()) * localData.density();
  }

  /////// Mandatory callback functions

  // `makerExecute` is the callback function to execute all offers that were posted on Mangrove by `this` contract.
  // it may not be overriden although it can be customized using `__lastLook__`, `__put__` and `__get__` hooks.
  // NB #1: When overriding the above hooks, the Offer Maker SHOULD make sure they do not revert in order to be able to post logs in case of bad executions.
  // NB #2: if `makerExecute` does revert, the offer will be considered to be refusing the trade.
  function makerExecute(MgvLib.SingleOrder calldata order)
    external
    override
    onlyCaller(address(MGV))
    returns (bytes32 ret)
  {
    if (!__lastLook__(order)) {
      // hook to check order details and decide whether `this` contract should renege on the offer.
      emit Reneged(order.outbound_tkn, order.inbound_tkn, order.offerId);
      return RENEGED;
    }
    uint missingPut = __put__(order.gives, order); // implements what should be done with the liquidity that is flashswapped by the offer taker to `this` contract
    if (missingPut > 0) {
      emit PutFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        missingPut
      );
      return PUTFAILURE;
    }
    uint missingGet = __get__(order.wants, order); // implements how `this` contract should make the outbound tokens available
    if (missingGet > 0) {
      emit GetFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        missingGet
      );
      return OUTOFLIQUIDITY;
    }
  }

  // `makerPosthook` is the callback function that is called by Mangrove *after* the offer execution.
  // It may not be overriden although it can be customized via the post-hooks `__posthookSuccess__`, `__posthookGetFailure__`, `__posthookReneged__` and `__posthookFallback__` (see below).
  // Offer Maker SHOULD make sure the overriden posthooks do not revert in order to be able to post logs in case of bad executions.
  function makerPosthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata result
  ) external override onlyCaller(address(MGV)) {
    if (result.mgvData == "mgv/tradeSuccess") {
      // if trade was a success
      __posthookSuccess__(order);
      return;
    }
    // if trade was aborted because of a lack of liquidity
    if (result.makerData == OUTOFLIQUIDITY) {
      __posthookGetFailure__(order);
      return;
    }
    // if trade was reneged on during lastLook
    if (result.makerData == RENEGED) {
      __posthookReneged__(order);
      return;
    }
    // if trade failed unexpectedly (`makerExecute` reverted or Mangrove failed to transfer the outbound tokens to the Offer Taker)
    __posthookFallback__(order, result);
    return;
  }

  ////// Customizable hooks for Taker Order'execution

  // Override this hook to describe where the inbound token, which are flashswapped by the Offer Taker, should go during Taker Order's execution.
  // `amount` is the quantity of outbound tokens whose destination is to be resolved.
  // All tokens that are not transfered to a different contract remain listed in the balance of `this` contract
  function __put__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    returns (uint);

  // Override this hook to implement fetching `amount` of outbound tokens, possibly from another source than `this` contract during Taker Order's execution.
  // For composability, return value MUST be the remaining quantity (i.e <= `amount`) of tokens remaining to be fetched.
  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    returns (uint);

  // Override this hook to implement a last look check during Taker Order's execution.
  // Return value should be `true` if Taker Order is acceptable.
  function __lastLook__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    returns (bool proceed)
  {
    order; //shh
    proceed = true;
  }

  ////// Customizable post-hooks.

  // Override this post-hook to implement what `this` contract should do when called back after a successfully executed order.
  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    virtual
  {
    order; // shh
  }

  // Override this post-hook to implement what `this` contract should do when called back after an order that failed to be executed because of a lack of liquidity (not enough outbound tokens).
  function __posthookGetFailure__(MgvLib.SingleOrder calldata order)
    internal
    virtual
  {
    order;
  }

  // Override this post-hook to implement what `this` contract should do when called back after an order that did not pass its last look (see `__lastLook__` hook).
  function __posthookReneged__(MgvLib.SingleOrder calldata order)
    internal
    virtual
  {
    order; //shh
  }

  // Override this post-hook to implement fallback behavior when Taker Order's execution failed unexpectedly. Information from Mangrove is accessible in `result.mgvData` for logging purpose.
  function __posthookFallback__(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata result
  ) internal virtual {
    order;
    result;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// SwingingMarketMaker.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../../Persistent.sol";

contract Mango is Persistent {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;

  event BidAtMaxPosition(address quote, address base, uint offerId);
  event AskAtMinPosition(address quote, address base, uint offerId);
  event Initialized(uint from, uint to, bool bidding);

  /** Immutables */
  // total number of Asks (resp. Bids)
  uint16 public immutable NSLOTS;

  // initial min price
  uint96 immutable BASE_0;
  uint96 immutable QUOTE_0;

  address public immutable BASE;
  address public immutable QUOTE;
  

  /** Mutables */
  //NB if one wants to allow this contract to be multi-makers one should use uint[][] ASKS/BIDS and allocate a new array for each maker.
  uint[] ASKS;
  uint[] BIDS;
  mapping(uint => uint) index_of_bid; // bidId -> index
  mapping(uint => uint) index_of_ask; // askId -> index

  //NB if one wants to allow this contract to be multi-makers one should use uint[] for each mutable fields to allow user specific parameters.
  int current_shift;

  // P_i = (Q_0 + i*delta)/B_0
  uint current_delta; // quote increment

  // triggers `__boundariesReached__` whenever amounts of bids/asks is below `current_min_offer_type`
  uint current_min_offer_type;

  // whether the strat reneges on offers
  bool paused = false;

  // Base and quote token treasuries
  address current_base_treasury;
  address current_quote_treasury;

  /** Sets the account from which base (resp. quote) tokens need to be fetched or put during trade execution*/
  function set_treasury(bool base, address treasury) external onlyAdmin {
    require(treasury!=address(0), "Mango/set_treasury/zeroAddress");
    if (base) {
      current_base_treasury = treasury;
    } else {
      current_quote_treasury = treasury;
    }
  }

  function get_treasury(bool base) external view onlyAdmin returns (address) {
    return base?current_base_treasury:current_quote_treasury;
  }

  /** Deposits received tokens into the corresponding treasury*/
  function __put__(uint amount, MgvLib.SingleOrder calldata order)
  internal
  virtual
  override
  returns (uint) {
    if (order.inbound_tkn == BASE && current_base_treasury != address(this)) {
      return IERC20(BASE).transfer(current_base_treasury, amount)?0:amount;
    }
    if (current_quote_treasury != address(this)) {
      return IERC20(QUOTE).transfer(current_quote_treasury, amount)?0:amount;
    }
    // order.inbound_tkn has to be either BASE or QUOTE so only possibility is `this` is treasury
    return 0;
  }

  /** Fetches required tokens from the corresponding treasury*/
  function __get__(uint amount, MgvLib.SingleOrder calldata order)
  internal
  virtual
  override
  returns (uint){
    if (order.outbound_tkn == BASE && current_base_treasury != address(this)) {
      return IERC20(BASE).transferFrom(current_base_treasury, address(this), amount)?0:amount;
    }
    if (current_quote_treasury != address(this)) {
      return IERC20(QUOTE).transferFrom(current_quote_treasury, address(this), amount)?0:amount;
    }
    // order.outbound_tkn has to be either BASE or QUOTE so only possibility is `this` is treasury
    return 0;
  }

  function retractOffers (uint from, uint to) external onlyAdmin returns (uint collected) {
    uint collected;
    for (uint i=from; i<to; i++) {
      collected += ASKS[i]>0?retractOfferInternal(BASE, QUOTE, ASKS[i], true):0;
      collected += BIDS[i]>0?retractOfferInternal(QUOTE, BASE, BIDS[i], true):0;
    }
  }

  /** Setters and getters */
  function get_delta() external view onlyAdmin returns (uint) {
    return current_delta;
  }

  function set_delta(uint delta) public mgvOrAdmin {
    current_delta = delta;
  }

  function get_shift() external view onlyAdmin returns (int) {
    return current_shift;
  }

  /** Shift the price (induced by quote amount) of n slots down or up */
  /** price at position i will be shifted (up or down depending on the sign of `shift`) of (shift*delta) / BASE_0 */
  function set_shift(int s) public mgvOrAdmin {
    if (s < 0) {
      negative_shift(uint(-s));
    } else {
      positive_shift(uint(s));
    }
  }

  function set_min_offer_type(uint m) public mgvOrAdmin {
    current_min_offer_type = m;
  }

  function get_offers() external view returns (uint[][2] memory offers) {
    offers[0] = new uint[](NSLOTS);
    offers[1] = new uint[](NSLOTS);
    for (uint i = 0; i < NSLOTS; i++) {
      offers[0][i] = BIDS[index_of_position(i)];
      offers[1][i] = ASKS[index_of_position(i)];
    }
  }

  // starts reneging all offers
  // NB reneged offers will not be reposted
  function pause() public mgvOrAdmin {
    paused = true;
  }

  function restart() external onlyAdmin {
    paused = false;
  }

  function __lastLook__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool proceed)
  {
    order; //shh
    proceed = !paused;
  }

  constructor(
    address payable mgv,
    address base,
    address quote,
    uint base_0,
    uint quote_0,
    uint nslots,
    uint delta
  ) MangroveOffer(mgv) {
    // sanity check
    require(
      nslots > 0 &&
        mgv != address(0) &&
        uint16(nslots) == nslots &&
        uint96(base_0) == base_0 &&
        uint96(quote_0) == quote_0,
      "Mango/constructor/invalidArguments"
    );
    BASE = base;
    QUOTE = quote;
    NSLOTS = uint16(nslots);
    ASKS = new uint[](nslots);
    BIDS = new uint[](nslots);
    BASE_0 = uint96(base_0);
    QUOTE_0 = uint96(quote_0);
    current_delta = delta;
    current_min_offer_type = 1;
    current_quote_treasury = msg.sender;
    current_base_treasury = msg.sender;
    OFR_GASREQ = 400_000; // dry run OK with 200_000
  }

  function writeOffer(
    uint index,
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint pivotId
  ) internal {
    inbound_tkn; // shh
    if (outbound_tkn == BASE) {
      // Asks
      if (ASKS[index] == 0) {
        // offer slot not initialized yet
        ASKS[index] = newOfferInternal({
          outbound_tkn: BASE,
          inbound_tkn: QUOTE,
          wants: wants,
          gives: gives,
          gasreq: OFR_GASREQ,
          gasprice: 0,
          pivotId: pivotId,
          provision: 0
        });
        index_of_ask[ASKS[index]] = index;
      } else {
        updateOfferInternal({
          outbound_tkn: BASE,
          inbound_tkn: QUOTE,
          wants: wants,
          gives: gives,
          gasreq: OFR_GASREQ,
          gasprice: 0,
          pivotId: pivotId,
          provision: 0,
          offerId: ASKS[index]
        });
      }
      if (position_of_index(index) <= current_min_offer_type) {
        __boundariesReached__(false, ASKS[index]);
      }
    } else {
      // Bids
      if (BIDS[index] == 0) {
        BIDS[index] = newOfferInternal({
          outbound_tkn: QUOTE,
          inbound_tkn: BASE,
          wants: wants,
          gives: gives,
          gasreq: OFR_GASREQ,
          gasprice: 0,
          pivotId: pivotId,
          provision: 0
        });
        index_of_bid[BIDS[index]] = index;
      } else {
        updateOfferInternal({
          outbound_tkn: QUOTE,
          inbound_tkn: BASE,
          wants: wants,
          gives: gives,
          gasreq: OFR_GASREQ,
          gasprice: 0,
          pivotId: pivotId,
          provision: 0,
          offerId: BIDS[index]
        });
      }
      if (position_of_index(index) >= NSLOTS - 1 - current_min_offer_type) {
        __boundariesReached__(true, BIDS[index]);
      }
    }
  }

  function _getPivot(uint[] calldata pivots, uint i)
    internal
    pure
    returns (uint)
  {
    if (pivots[i] != 0) {
      return pivots[i];
    } else {
      return 0;
    }
  }

  function initialize(
    bool bidding, // if true, OB slots will be populated
    bool withBase,
    uint from, // slice (from included)
    uint to, // to index excluded
    uint[][2] calldata pivotIds, // `pivotIds[0][i]` ith pivots for bids, `pivotIds[1][i]` ith pivot for asks
    uint[] calldata tokenAmounts
  ) public mgvOrAdmin {
    /** Initializing Asks and Bids */
    /** NB we assume Mangrove is already provisioned for posting NSLOTS asks and NSLOTS bids*/
    /** NB cannot post newOffer with infinite gasreq since fallback OFR_GASREQ is not defined yet (and default is likely wrong) */
    require(
      to > from && pivotIds[0].length == to - from,
      "Mango/initialize/invalidSlice"
    );
    require(
      tokenAmounts.length == to - from,
      "Mango/initialize/invalidBaseAmounts"
    );
    require(!bidding || to != NSLOTS, "Mango/initialize/NoSlotForAsks"); // bidding => slice doesn't fill the book
    require(bidding || from != 0, "Mango/initialize/NoSlotForBids"); // asking => slice doesn't start from MinPrice
    uint i;
    for (i = from; i < to; i++) {
      if (bidding) {
        uint bidPivot = _getPivot(pivotIds[0], i - from);
        bidPivot = bidPivot > 0
          ? bidPivot // taking pivot from the user
          : i > 0
          ? BIDS[i - 1]
          : 0; // otherwise getting last inserted offer as pivot
        updateBid({
          index: i,
          withBase: withBase,
          amount: tokenAmounts[i - from],
          pivotId: bidPivot
        });
      } else {
        uint askPivot = _getPivot(pivotIds[1], i - from);
        askPivot = askPivot > 0
          ? askPivot // taking pivot from the user
          : i > 0
          ? ASKS[i - 1]
          : 0; // otherwise getting last inserted offer as pivot
        updateAsk({
          index: i,
          withBase: withBase,
          amount: tokenAmounts[i - from],
          pivotId: askPivot
        });
      }
    }
    emit Initialized({from: from, to: to, bidding: bidding});
  }

  // returns the value of x in the ring [0,m]
  // i.e if x>=0 this is just x % m
  // if x<0 this is m + (x % m)
  function modulo(int x, uint m) internal pure returns (uint) {
    if (x >= 0) {
      return uint(x) % m;
    } else {
      return uint(int(m) + (x % int(m)));
    }
  }

  /** Minimal amount of quotes for the general term of the `__quote_progression__` */
  /** If min price was not shifted this is just `QUOTE_0` */
  /** In general this is QUOTE_0 + shift*delta */
  function quote_min() internal view returns (uint) {
    int qm = int(uint(QUOTE_0)) + current_shift * int(current_delta);
    require(qm > 0, "Mango/quote_min/ShiftUnderflow");
    return (uint(qm));
  }

  /** Returns the position in the order book of the offer associated to this index `i` */
  function position_of_index(uint i) internal view returns (uint) {
    // position(i) = (i+shift) % N
    return modulo(int(i) - current_shift, NSLOTS);
  }

  /** Returns the index in the ring of offers at which the offer Id at position `p` in the book is stored */
  function index_of_position(uint p) internal view returns (uint) {
    return modulo(int(p) + current_shift, NSLOTS);
  }

  /**Next index in the ring of offers */
  function next_index(uint i) internal view returns (uint) {
    return (i + 1) % NSLOTS;
  }

  /**Previous index in the ring of offers */
  function prev_index(uint i) internal view returns (uint) {
    return i > 0 ? i - 1 : NSLOTS - 1;
  }

  /** Function that determines the amount of quotes that are offered at position i of the OB depending on initial_price and paramater delta*/
  /** Here the default is an arithmetic progression */
  function __quote_progression__(uint position)
    internal
    view
    virtual
    returns (uint)
  {
    return current_delta * position + quote_min();
  }

  /** Returns the quantity of quote tokens for an offer at position `p` given an amount of Base tokens (eq. 2)*/
  function quotes_of_position(uint p, uint base_amount)
    internal
    view
    returns (uint)
  {
    return (__quote_progression__(p) * base_amount) / BASE_0;
  }

  /** Returns the quantity of base tokens for an offer at position `p` given an amount of quote tokens (eq. 3)*/
  function bases_of_position(uint p, uint quote_amount)
    internal
    view
    returns (uint)
  {
    return (quote_amount * BASE_0) / __quote_progression__(p);
  }

  /** Recenter the order book by shifting min price up `s` positions in the book */
  /** As a consequence `s` Bids will be cancelled and `s` new asks will be posted */
  function positive_shift(uint s) internal {
    require(s < NSLOTS, "Mango/shift/positiveShiftTooLarge");
    uint index = index_of_position(0);
    current_shift += int(s); // updating new shift
    // Warning: from now on position_of_index reflects the new shift
    // One must progress relative to index when retracting offers
    while (s > 0) {
      // slots occupied by [Bids[index],..,Bids[index+`s` % N]] are retracted
      if (BIDS[index] != 0) {
        retractOfferInternal({
          outbound_tkn: QUOTE,
          inbound_tkn: BASE,
          offerId: BIDS[index],
          deprovision: false
        });
      }
      // slots are replaced by `s` Asks.
      // NB the price of Ask[index] is computed given the new position associated to `index`
      // because the shift has been updated above

      // `pos` is the offer position in the OB (not the array)
      uint pos = position_of_index(index);
      // defining new_gives (in bases) based on default quote amount for new offers
      // in order to minimize base input to the strat
      uint new_gives = bases_of_position(pos, QUOTE_0);
      writeOffer({
        index: index,
        outbound_tkn: BASE,
        inbound_tkn: QUOTE,
        wants: QUOTE_0,
        gives: new_gives,
        pivotId: pos > 0 ? ASKS[index_of_position(pos - 1)] : 0
      });
      s--;
      index = next_index(index);
    }
  }

  /** Recenter the order book by shifting max price down `s` positions in the book */
  /** As a consequence `s` Asks will be cancelled and `s` new Bids will be posted */
  function negative_shift(uint s) internal {
    require(s < NSLOTS, "Mango/shift/NegativeShiftTooLarge");
    uint index = index_of_position(NSLOTS - 1);
    current_shift -= int(s); // updating new shift
    // Warning: from now on position_of_index reflects the new shift
    // One must progress relative to index when retracting offers
    while (s > 0) {
      // slots occupied by [Asks[index-`s` % N],..,Asks[index]] are retracted
      if (ASKS[index] != 0) {
        retractOfferInternal({
          outbound_tkn: BASE,
          inbound_tkn: QUOTE,
          offerId: ASKS[index],
          deprovision: false
        });
      }
      // slots are replaced by `s` Bids.
      // NB the price of Bids[index] is computed given the new position associated to `index`
      // because the shift has been updated above

      // `pos` is the offer position in the OB (not the array)
      uint pos = position_of_index(index);
      uint new_wants = bases_of_position(pos, QUOTE_0);
      writeOffer({
        index: index,
        outbound_tkn: QUOTE,
        inbound_tkn: BASE,
        wants: new_wants,
        gives: QUOTE_0,
        pivotId: pos < NSLOTS - 1 ? BIDS[index_of_position(pos + 1)] : 0
      });
      s--;
      index = prev_index(index);
    }
  }

  // for reposting partial filled offers one always gives the residual (default behavior)
  // and adapts wants to the new price (if different).
  function __residualWants__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    if (order.outbound_tkn == BASE) {
      // Ask offer (wants QUOTE)
      uint index = index_of_ask[order.offerId];
      uint residual_base = __residualGives__(order); // default
      if (residual_base == 0) {
        return 0;
      }
      return quotes_of_position(position_of_index(index), residual_base);
    } else {
      // Bid order (wants BASE)
      uint index = index_of_bid[order.offerId];
      uint residual_quote = __residualGives__(order); // default
      if (residual_quote == 0) {
        return 0;
      }
      return bases_of_position(position_of_index(index), residual_quote);
    }
  }

  /** Define what to do when the AMM boundaries are reached (either when reposting a bid or a ask) */
  function __boundariesReached__(bool bid, uint offerId) internal virtual {
    if (bid) {
      emit BidAtMaxPosition(QUOTE, BASE, offerId);
    } else {
      emit AskAtMinPosition(BASE, QUOTE, offerId);
    }
  }

  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
  {
    // reposting residual of offer using override `__newWants__` and default `__newGives` for new price
    super.__posthookSuccess__(order);
    if (order.outbound_tkn == BASE) {
      // Ask Offer (`this` contract just sold some BASE @ pos)
      uint pos = position_of_index(index_of_ask[order.offerId]);
      // bid for some BASE token with the received QUOTE tokens @ pos-1
      if (pos > 0) {
        updateBid({
          index: index_of_position(pos - 1),
          withBase: false,
          amount: order.gives,
          pivotId: 0
        });
      } else {
        // Ask cannot be at Pmin unless a shift has eliminated all bids
        emit PosthookFail(
          order.outbound_tkn,
          order.inbound_tkn,
          order.offerId,
          "Mango/posthook/BuyingOutOfPriceRange"
        );
        return;
      }
    } else {
      // Bid offer (`this` contract just bought some BASE)
      uint pos = position_of_index(index_of_bid[order.offerId]);
      // ask for some QUOTE tokens in exchange of the received BASE tokens @ pos+1
      if (pos < NSLOTS - 1) {
        updateAsk({
          index: index_of_position(pos + 1),
          withBase: true,
          amount: order.gives,
          pivotId: 0
        });
      } else {
        // Take profit
        emit PosthookFail(
          order.outbound_tkn,
          order.inbound_tkn,
          order.offerId,
          "Mango/posthook/SellingOutOfPriceRange"
        );
        return;
      }
    }
  }

  function updateBid(
    uint index,
    bool withBase,
    uint amount,
    uint pivotId
  ) internal {
    // outbound : QUOTE, inbound: BASE
    P.Offer.t offer = MGV.offers(QUOTE, BASE, BIDS[index]);

    uint position = position_of_index(index);
    uint new_wants;
    uint new_gives;
    if (withBase) {
      // amount: BASE
      new_wants = amount + offer.wants();
      new_gives = quotes_of_position(position, new_wants);
    } else {
      new_gives = amount + offer.gives();
      new_wants = bases_of_position(position, new_gives);
    }
    uint pivot;
    if (offer.gives() == 0) {
      // offer was not live
      if (pivotId != 0) {
        pivot = pivotId;
      } else {
        if (position > 0) {
          pivot = BIDS[index_of_position(position - 1)]; // if this offer is no longer in the book will start form best
        } else {
          pivot = offer.prev(); // trying previous offer on Mangrove as a pivot
        }
      }
    } else {
      // offer is live, so reusing its id for pivot
      pivot = BIDS[index];
    }
    writeOffer({
      index: index,
      outbound_tkn: QUOTE,
      inbound_tkn: BASE,
      wants: new_wants,
      gives: new_gives,
      pivotId: pivot
    });
  }

  function updateAsk(
    uint index,
    bool withBase,
    uint amount,
    uint pivotId
  ) internal {
    // outbound : BASE, inbound: QUOTE
    P.Offer.t offer = MGV.offers(BASE, QUOTE, ASKS[index]);
    uint position = position_of_index(index);
    uint new_gives;
    uint new_wants;
    if (withBase) {
      // amount: BASE
      new_gives = amount + offer.gives(); // in BASE
      new_wants = quotes_of_position(position, new_gives);
    } else {
      new_wants = amount + offer.wants(); // in QUOTES
      new_gives = bases_of_position(position, new_wants);
    }

    uint pivot;
    if (offer.gives() == 0) {
      // offer was not live
      if (pivotId != 0) {
        pivot = pivotId;
      } else {
        if (position > 0) {
          pivot = ASKS[index_of_position(position - 1)]; // if this offer is no longer in the book will start form best
        } else {
          pivot = offer.prev(); // trying previous offer on Mangrove as a pivot
        }
      }
    } else {
      // offer is live, so reusing its id for pivot
      pivot = ASKS[index];
    }
    writeOffer({
      index: index,
      outbound_tkn: BASE,
      inbound_tkn: QUOTE,
      wants: new_wants,
      gives: new_gives,
      pivotId: pivot
    });
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Persistent.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "./SingleUser.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract Persistent is SingleUser {
  using P.Offer for P.Offer.t;
  using P.OfferDetail for P.OfferDetail.t;

  function __residualWants__(MgvLib.SingleOrder calldata order) internal virtual returns (uint){
    return order.offer.wants() - order.gives;
  }

  function __residualGives__(MgvLib.SingleOrder calldata order) internal virtual returns (uint){
    return order.offer.gives() - order.wants;
  }

  function __posthookSuccess__(MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
  {
    uint new_gives = __residualGives__(order);
    uint new_wants = __residualWants__(order);
    try
      MGV.updateOffer(
        order.outbound_tkn,
        order.inbound_tkn,
        new_wants,
        new_gives,
        order.offerDetail.gasreq(),
        order.offerDetail.gasprice(),
        order.offer.next(),
        order.offerId
      )
    {} catch Error(string memory message) {
      emit PosthookFail(
        order.outbound_tkn,
        order.inbound_tkn,
        order.offerId,
        message
      );
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../MangroveOffer.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract SingleUser is MangroveOffer {
  function balanceOnMangrove() external view returns (uint) {
    return MGV.balanceOf(address(this));
  }

  function tokenBalance(address token) external view returns (uint) {
    return IERC20(token).balanceOf(address(this));
  }

  /// transfers token stored in `this` contract to some recipient address
  function redeemToken(address token, uint amount)
    external
    override
    onlyAdmin
    returns (bool success)
  {
    success = _transferToken(token, msg.sender, amount);
  }

  /// trader needs to approve Mangrove to let it perform outbound token transfer at the end of the `makerExecute` function
  function approveMangrove(address outbound_tkn, uint amount)
    external
    override
    onlyAdmin
  {
    _approveMangrove(outbound_tkn, amount);
  }

  function fundMangrove() external payable override {
    fundMangroveInternal(msg.value);
  }

  function fundMangroveInternal(uint provision) internal {
    // increasing the provision of `this` contract
    if (provision>0) {
      MGV.fund{value: provision}();
    }
  }

  /// withdraws ETH from the bounty vault of the Mangrove.
  function withdrawFromMangrove(address receiver, uint amount)
    external
    override
    onlyAdmin
    returns (bool)
  {
    return _withdrawFromMangrove(receiver, amount);
  }

  // Posting a new offer on the (`outbound_tkn,inbound_tkn`) Offer List of Mangrove.
  // NB #1: Offer maker MUST:
  // * Approve Mangrove for at least `gives` amount of `outbound_tkn`.
  // * Make sure that offer maker has enough WEI provision on Mangrove to cover for the new offer bounty
  // * Make sure that `gasreq` and `gives` yield a sufficient offer density
  // NB #2: This function may revert when the above points are not met, it is thus made external only so that it can be encapsulated when called during `makerExecute`.
  function newOffer(
    address outbound_tkn, // address of the ERC20 contract managing outbound tokens
    address inbound_tkn, // address of the ERC20 contract managing outbound tokens
    uint wants, // amount of `inbound_tkn` required for full delivery
    uint gives, // max amount of `outbound_tkn` promised by the offer
    uint gasreq, // max gas required by the offer when called. If maxUint256 is used here, default `OFR_GASREQ` will be considered instead
    uint gasprice, // gasprice that should be consider to compute the bounty (Mangrove's gasprice will be used if this value is lower)
    uint pivotId // identifier of an offer in the (`outbound_tkn,inbound_tkn`) Offer List after which the new offer should be inserted (gas cost of insertion will increase if the `pivotId` is far from the actual position of the new offer)
  ) external payable override onlyAdmin returns (uint offerId) {
    return newOfferInternal(
        outbound_tkn,
        inbound_tkn,
        wants,
        gives,
        gasreq,
        gasprice,
        pivotId,
        msg.value
    );
  }

  function newOfferInternal(
    address outbound_tkn, // address of the ERC20 contract managing outbound tokens
    address inbound_tkn, // address of the ERC20 contract managing outbound tokens
    uint wants, // amount of `inbound_tkn` required for full delivery
    uint gives, // max amount of `outbound_tkn` promised by the offer
    uint gasreq, // max gas required by the offer when called. If maxUint256 is used here, default `OFR_GASREQ` will be considered instead
    uint gasprice, // gasprice that should be consider to compute the bounty (Mangrove's gasprice will be used if this value is lower)
    uint pivotId,
    uint provision
  ) internal returns (uint offerId) {
    if (provision > 0) {
      MGV.fund{value: provision}();
    }
    if (gasreq > type(uint24).max) {
      gasreq = OFR_GASREQ;
    }
    // this call could revert if this contract does not have the provision to cover the bounty
    offerId = MGV.newOffer(
      outbound_tkn,
      inbound_tkn,
      wants,
      gives,
      gasreq,
      gasprice,
      pivotId
    );
  }


  //  Updates an existing `offerId` on the Mangrove. `updateOffer` rely on the same offer requirements as `newOffer` and may throw if they are not met.
  //  Additionally `updateOffer` will thow if `this` contract is not the owner of `offerId`.
  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable override onlyAdmin {
    updateOfferInternal(
      outbound_tkn,
      inbound_tkn,
      wants,
      gives,
      gasreq,
      gasprice,
      pivotId,
      offerId,
      msg.value
    );
  }

function updateOfferInternal(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId,
    uint provision // dangerous to use msg.value in a internal call
  ) internal {
    if (provision > 0) {
      MGV.fund{value: provision}();
    }
    if (gasreq > type(uint24).max) {
      gasreq = OFR_GASREQ;
    }
    MGV.updateOffer(
      outbound_tkn,
      inbound_tkn,
      wants,
      gives,
      gasreq,
      gasprice,
      pivotId,
      offerId
    );
  }


  // Retracts `offerId` from the (`outbound_tkn`,`inbound_tkn`) Offer list of Mangrove. Function call will throw if `this` contract is not the owner of `offerId`.
  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) external override onlyAdmin returns (uint) {
    return retractOfferInternal(
      outbound_tkn, 
      inbound_tkn, 
      offerId, 
      deprovision
    );
  }

  function retractOfferInternal(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision
  ) internal returns (uint) {
    return MGV.retractOffer(
      outbound_tkn,
      inbound_tkn,
      offerId,
      deprovision
    );
  }

  function getMissingProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) public view override returns (uint) {
    return
      _getMissingProvision(
        MGV.balanceOf(address(this)),
        outbound_tkn,
        inbound_tkn,
        gasreq,
        gasprice,
        offerId
      );
  }

  function __put__(
    uint, /*amount*/
    MgvLib.SingleOrder calldata
  ) internal virtual override returns (uint) {
    return 0;
  }

  function __get__(uint amount, MgvLib.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    uint balance = IERC20(order.outbound_tkn).balanceOf(address(this));
    if (balance >= amount) {
      return 0;
    } else {
      return (amount - balance);
    }
  }
}

pragma solidity >=0.7.0;
pragma abicoder v2;

import "../../MgvLib.sol";

interface IOfferLogic is IMaker {
  ///////////////////
  // MangroveOffer //
  ///////////////////

  /** @notice Events */

  // Logged whenever something went wrong during `makerPosthook` execution
  event PosthookFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId,
    string message
  );

  // Logged whenever `__get__` hook failed to fetch the totality of the requested amount
  event GetFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId,
    uint missingAmount
  );

  // Logged whenever `__put__` hook failed to deposit the totality of the requested amount
  event PutFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId,
    uint missingAmount
  );

  // Logged whenever `__lastLook__` hook returned `false`
  event Reneged(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId
  );

  // Offer logic default gas required --value is used in update and new offer if maxUint is given
  function OFR_GASREQ() external returns (uint);

  // returns missing provision on Mangrove, should `offerId` be reposted using `gasreq` and `gasprice` parameters
  // if `offerId` is not in the `outbound_tkn,inbound_tkn` offer list, the totality of the necessary provision is returned
  function getMissingProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) external view returns (uint);

  // Changing OFR_GASREQ of the logic
  function setGasreq(uint gasreq) external;

  function balanceOnMangrove() external view returns (uint balance);

  function tokenBalance(address token)
    external
    view
    returns (uint token_balance);

  function redeemToken(address token, uint amount)
    external
    returns (bool success);

  function approveMangrove(address outbound_tkn, uint amount) external;

  function withdrawFromMangrove(address receiver, uint amount)
    external
    returns (bool noRevert);

  function fundMangrove() external payable;

  function newOffer(
    address outbound_tkn, // address of the ERC20 contract managing outbound tokens
    address inbound_tkn, // address of the ERC20 contract managing outbound tokens
    uint wants, // amount of `inbound_tkn` required for full delivery
    uint gives, // max amount of `outbound_tkn` promised by the offer
    uint gasreq, // max gas required by the offer when called. If maxUint256 is used here, default `OFR_GASREQ` will be considered instead
    uint gasprice, // gasprice that should be consider to compute the bounty (Mangrove's gasprice will be used if this value is lower)
    uint pivotId // identifier of an offer in the (`outbound_tkn,inbound_tkn`) Offer List after which the new offer should be inserted (gas cost of insertion will increase if the `pivotId` is far from the actual position of the new offer)
  ) external payable returns (uint offerId);

  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable;

  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) external returns (uint received);
}

// SPDX-License-Identifier:	BSD-2-Clause

// AccessedControlled.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

contract AccessControlled {
  address public admin;

  constructor() {
    admin = msg.sender;
  }

  modifier onlyCaller(address caller) {
    require(
      caller == address(0) || msg.sender == caller,
      "AccessControlled/Invalid"
    );
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "AccessControlled/Invalid");
    _;
  }

  function setAdmin(address _admin) external onlyAdmin {
    admin = _admin;
  }
}

// SPDX-License-Identifier:	BSD-3-Clause

// Copyright 2020 Compound Labs, Inc.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;

/**
 * @title Careful Math
 * @author Compound
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
  /**
   * @dev Possible error codes that we can return
   */
  enum MathError {
    NO_ERROR,
    DIVISION_BY_ZERO,
    INTEGER_OVERFLOW,
    INTEGER_UNDERFLOW
  }

  /**
   * @dev Multiplies two numbers, returns an error on overflow.
   */
  function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
    if (a == 0) {
      return (MathError.NO_ERROR, 0);
    }

    uint c = a * b;

    if (c / a != b) {
      return (MathError.INTEGER_OVERFLOW, 0);
    } else {
      return (MathError.NO_ERROR, c);
    }
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient.
   */
  function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
    if (b == 0) {
      return (MathError.DIVISION_BY_ZERO, 0);
    }

    return (MathError.NO_ERROR, a / b);
  }

  /**
   * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
   */
  function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
    if (b <= a) {
      return (MathError.NO_ERROR, a - b);
    } else {
      return (MathError.INTEGER_UNDERFLOW, 0);
    }
  }

  /**
   * @dev Adds two numbers, returns an error on overflow.
   */
  function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
    uint c = a + b;

    if (c >= a) {
      return (MathError.NO_ERROR, c);
    } else {
      return (MathError.INTEGER_OVERFLOW, 0);
    }
  }

  /**
   * @dev add a and b and then subtract c
   */
  function addThenSubUInt(
    uint a,
    uint b,
    uint c
  ) internal pure returns (MathError, uint) {
    (MathError err0, uint sum) = addUInt(a, b);

    if (err0 != MathError.NO_ERROR) {
      return (err0, 0);
    }

    return subUInt(sum, c);
  }

  /**
   * @dev min and max functions
   */
  function min(uint a, uint b) internal pure returns (uint) {
    return (a < b ? a : b);
  }

  function max(uint a, uint b) internal pure returns (uint) {
    return (a > b ? a : b);
  }

  uint constant MAXUINT = type(uint).max;
  uint constant MAXUINT96 = type(uint96).max;
  uint constant MAXUINT24 = type(uint24).max;
}

// SPDX-License-Identifier:	BSD-3-Clause

// Copyright 2020 Compound Labs, Inc.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;

import "./CarefulMath.sol";
import "./ExponentialNoError.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @dev Legacy contract for compatibility reasons with existing contracts that still use MathError
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath, ExponentialNoError {
  /**
   * @dev Creates an exponential from numerator and denominator values.
   *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
   *            or if `denom` is zero.
   */
  function getExp(uint num, uint denom)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: rational}));
  }

  /**
   * @dev Adds two exponentials, returning a new exponential.
   */
  function addExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

    return (error, Exp({mantissa: result}));
  }

  /**
   * @dev Subtracts two exponentials, returning a new exponential.
   */
  function subExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

    return (error, Exp({mantissa: result}));
  }

  /**
   * @dev Multiply an Exp by a scalar, returning a new Exp.
   */
  function mulScalar(Exp memory a, uint scalar)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mulScalarTruncate(Exp memory a, uint scalar)
    internal
    pure
    returns (MathError, uint)
  {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(product));
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mulScalarTruncateAddUInt(
    Exp memory a,
    uint scalar,
    uint addend
  ) internal pure returns (MathError, uint) {
    (MathError err, Exp memory product) = mulScalar(a, scalar);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return addUInt(truncate(product), addend);
  }

  /**
   * @dev Divide an Exp by a scalar, returning a new Exp.
   */
  function divScalar(Exp memory a, uint scalar)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
  }

  /**
   * @dev Divide a scalar by an Exp, returning a new Exp.
   */
  function divScalarByExp(uint scalar, Exp memory divisor)
    internal
    pure
    returns (MathError, Exp memory)
  {
    /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
    (MathError err0, uint numerator) = mulUInt(expScale, scalar);
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }
    return getExp(numerator, divisor.mantissa);
  }

  /**
   * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
   */
  function divScalarByExpTruncate(uint scalar, Exp memory divisor)
    internal
    pure
    returns (MathError, uint)
  {
    (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
    if (err != MathError.NO_ERROR) {
      return (err, 0);
    }

    return (MathError.NO_ERROR, truncate(fraction));
  }

  /**
   * @dev Multiplies two exponentials, returning a new exponential.
   */
  function mulExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    (MathError err0, uint doubleScaledProduct) = mulUInt(
      a.mantissa,
      b.mantissa
    );
    if (err0 != MathError.NO_ERROR) {
      return (err0, Exp({mantissa: 0}));
    }

    // We add half the scale before dividing so that we get rounding instead of truncation.
    //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
    // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
    (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(
      halfExpScale,
      doubleScaledProduct
    );
    if (err1 != MathError.NO_ERROR) {
      return (err1, Exp({mantissa: 0}));
    }

    (MathError err2, uint product) = divUInt(
      doubleScaledProductWithHalfScale,
      expScale
    );
    // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
    assert(err2 == MathError.NO_ERROR);

    return (MathError.NO_ERROR, Exp({mantissa: product}));
  }

  /**
   * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
   */
  function mulExp(uint a, uint b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
  }

  /**
   * @dev Multiplies three exponentials, returning a new exponential.
   */
  function mulExp3(
    Exp memory a,
    Exp memory b,
    Exp memory c
  ) internal pure returns (MathError, Exp memory) {
    (MathError err, Exp memory ab) = mulExp(a, b);
    if (err != MathError.NO_ERROR) {
      return (err, ab);
    }
    return mulExp(ab, c);
  }

  /**
   * @dev Divides two exponentials, returning a new exponential.
   *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
   *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
   */
  function divExp(Exp memory a, Exp memory b)
    internal
    pure
    returns (MathError, Exp memory)
  {
    return getExp(a.mantissa, b.mantissa);
  }
}

// SPDX-License-Identifier:	BSD-3-Clause

// Copyright 2020 Compound Labs, Inc.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
  uint constant expScale = 1e18;
  uint constant doubleScale = 1e36;
  uint constant halfExpScale = expScale / 2;
  uint constant mantissaOne = expScale;

  struct Exp {
    uint mantissa;
  }

  struct Double {
    uint mantissa;
  }

  /**
   * @dev Truncates the given exp to a whole number value.
   *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
   */
  function truncate(Exp memory exp) internal pure returns (uint) {
    // Note: We are not using careful math here as we're performing a division that cannot fail
    return exp.mantissa / expScale;
  }

  /**
   * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
   */
  function mul_ScalarTruncate(Exp memory a, uint scalar)
    internal
    pure
    returns (uint)
  {
    Exp memory product = mul_(a, scalar);
    return truncate(product);
  }

  /**
   * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
   */
  function mul_ScalarTruncateAddUInt(
    Exp memory a,
    uint scalar,
    uint addend
  ) internal pure returns (uint) {
    Exp memory product = mul_(a, scalar);
    return add_(truncate(product), addend);
  }

  /**
   * @dev Checks if first Exp is less than second Exp.
   */
  function lessThanExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa < right.mantissa;
  }

  /**
   * @dev Checks if left Exp <= right Exp.
   */
  function lessThanOrEqualExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa <= right.mantissa;
  }

  /**
   * @dev Checks if left Exp > right Exp.
   */
  function greaterThanExp(Exp memory left, Exp memory right)
    internal
    pure
    returns (bool)
  {
    return left.mantissa > right.mantissa;
  }

  /**
   * @dev returns true if Exp is exactly zero
   */
  function isZeroExp(Exp memory value) internal pure returns (bool) {
    return value.mantissa == 0;
  }

  function safe224(uint n, string memory errorMessage)
    internal
    pure
    returns (uint224)
  {
    require(n < 2**224, errorMessage);
    return uint224(n);
  }

  function safe32(uint n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({mantissa: add_(a.mantissa, b.mantissa)});
  }

  function add_(uint a, uint b) internal pure returns (uint) {
    return add_(a, b, "addition overflow");
  }

  function add_(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({mantissa: sub_(a.mantissa, b.mantissa)});
  }

  function sub_(uint a, uint b) internal pure returns (uint) {
    return sub_(a, b, "subtraction underflow");
  }

  function sub_(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
  }

  function mul_(Exp memory a, uint b) internal pure returns (Exp memory) {
    return Exp({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint a, Exp memory b) internal pure returns (uint) {
    return mul_(a, b.mantissa) / expScale;
  }

  function mul_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
  }

  function mul_(Double memory a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: mul_(a.mantissa, b)});
  }

  function mul_(uint a, Double memory b) internal pure returns (uint) {
    return mul_(a, b.mantissa) / doubleScale;
  }

  function mul_(uint a, uint b) internal pure returns (uint) {
    return mul_(a, b, "multiplication overflow");
  }

  function mul_(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    if (a == 0 || b == 0) {
      return 0;
    }
    uint c = a * b;
    require(c / a == b, errorMessage);
    return c;
  }

  function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
  }

  function div_(Exp memory a, uint b) internal pure returns (Exp memory) {
    return Exp({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint a, Exp memory b) internal pure returns (uint) {
    return div_(mul_(a, expScale), b.mantissa);
  }

  function div_(Double memory a, Double memory b)
    internal
    pure
    returns (Double memory)
  {
    return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
  }

  function div_(Double memory a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: div_(a.mantissa, b)});
  }

  function div_(uint a, Double memory b) internal pure returns (uint) {
    return div_(mul_(a, doubleScale), b.mantissa);
  }

  function div_(uint a, uint b) internal pure returns (uint) {
    return div_(a, b, "divide by zero");
  }

  function div_(
    uint a,
    uint b,
    string memory errorMessage
  ) internal pure returns (uint) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function fraction(uint a, uint b) internal pure returns (Double memory) {
    return Double({mantissa: div_(mul_(a, doubleScale), b)});
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.10 <=0.8.10;

/*
 * Error logging
 * Author: Zac Williamson, AZTEC
 * Licensed under the Apache 2.0 license
 */

library consolerr {
  function errorBytes(string memory reasonString, bytes memory varA)
    internal
    pure
  {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendBytes(varA, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function error(string memory reasonString, bytes32 varA) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    append0x(errorPtr);
    appendBytes32(varA, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function error(
    string memory reasonString,
    bytes32 varA,
    bytes32 varB
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    append0x(errorPtr);
    appendBytes32(varA, errorPtr);
    appendComma(errorPtr);
    append0x(errorPtr);
    appendBytes32(varB, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function error(
    string memory reasonString,
    bytes32 varA,
    bytes32 varB,
    bytes32 varC
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    append0x(errorPtr);
    appendBytes32(varA, errorPtr);
    appendComma(errorPtr);
    append0x(errorPtr);
    appendBytes32(varB, errorPtr);
    appendComma(errorPtr);
    append0x(errorPtr);
    appendBytes32(varC, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorBytes32(string memory reasonString, bytes32 varA)
    internal
    pure
  {
    error(reasonString, varA);
  }

  function errorBytes32(
    string memory reasonString,
    bytes32 varA,
    bytes32 varB
  ) internal pure {
    error(reasonString, varA, varB);
  }

  function errorBytes32(
    string memory reasonString,
    bytes32 varA,
    bytes32 varB,
    bytes32 varC
  ) internal pure {
    error(reasonString, varA, varB, varC);
  }

  function errorAddress(string memory reasonString, address varA)
    internal
    pure
  {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendAddress(varA, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorAddress(
    string memory reasonString,
    address varA,
    address varB
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendAddress(varA, errorPtr);
    appendComma(errorPtr);
    appendAddress(varB, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorAddress(
    string memory reasonString,
    address varA,
    address varB,
    address varC
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendAddress(varA, errorPtr);
    appendComma(errorPtr);
    appendAddress(varB, errorPtr);
    appendComma(errorPtr);
    appendAddress(varC, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorUint(string memory reasonString, uint varA) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendUint(varA, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorUint(
    string memory reasonString,
    uint varA,
    uint varB
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendUint(varA, errorPtr);
    appendComma(errorPtr);
    appendUint(varB, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function errorUint(
    string memory reasonString,
    uint varA,
    uint varB,
    uint varC
  ) internal pure {
    (bytes32 revertPtr, bytes32 errorPtr) = initErrorPtr();
    appendString(reasonString, errorPtr);
    appendUint(varA, errorPtr);
    appendComma(errorPtr);
    appendUint(varB, errorPtr);
    appendComma(errorPtr);
    appendUint(varC, errorPtr);

    assembly {
      revert(revertPtr, add(mload(errorPtr), 0x44))
    }
  }

  function toAscii(bytes32 input)
    internal
    pure
    returns (bytes32 hi, bytes32 lo)
  {
    assembly {
      for {
        let j := 0
      } lt(j, 32) {
        j := add(j, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        if gt(slice, 0x39) {
          slice := add(slice, 39)
        }
        lo := add(lo, shl(mul(8, j), slice))
        input := shr(4, input)
      }
      for {
        let k := 0
      } lt(k, 32) {
        k := add(k, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        if gt(slice, 0x39) {
          slice := add(slice, 39)
        }
        hi := add(hi, shl(mul(8, k), slice))
        input := shr(4, input)
      }
    }
  }

  function appendComma(bytes32 stringPtr) internal pure {
    assembly {
      let stringLen := mload(stringPtr)

      mstore(add(stringPtr, add(stringLen, 0x20)), ", ")
      mstore(stringPtr, add(stringLen, 2))
    }
  }

  function append0x(bytes32 stringPtr) internal pure {
    assembly {
      let stringLen := mload(stringPtr)
      mstore(add(stringPtr, add(stringLen, 0x20)), "0x")
      mstore(stringPtr, add(stringLen, 2))
    }
  }

  function appendString(string memory toAppend, bytes32 stringPtr)
    internal
    pure
  {
    assembly {
      let appendLen := mload(toAppend)
      let stringLen := mload(stringPtr)
      let appendPtr := add(stringPtr, add(0x20, stringLen))
      for {
        let i := 0
      } lt(i, appendLen) {
        i := add(i, 0x20)
      } {
        mstore(add(appendPtr, i), mload(add(toAppend, add(i, 0x20))))
      }

      // update string length
      mstore(stringPtr, add(stringLen, appendLen))
    }
  }

  function appendBytes(bytes memory toAppend, bytes32 stringPtr) internal pure {
    uint bytesLen;
    bytes32 inPtr;
    assembly {
      bytesLen := mload(toAppend)
      inPtr := add(toAppend, 0x20)
    }

    for (uint i = 0; i < bytesLen; i += 0x20) {
      bytes32 slice;
      assembly {
        slice := mload(inPtr)
        inPtr := add(inPtr, 0x20)
      }
      appendBytes32(slice, stringPtr);
    }

    uint offset = bytesLen % 0x20;
    if (offset > 0) {
      // update length
      assembly {
        let lengthReduction := sub(0x20, offset)
        let len := mload(stringPtr)
        mstore(stringPtr, sub(len, lengthReduction))
      }
    }
  }

  function appendBytes32(bytes32 input, bytes32 stringPtr) internal pure {
    assembly {
      let hi
      let lo
      for {
        let j := 0
      } lt(j, 32) {
        j := add(j, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        slice := add(slice, mul(39, gt(slice, 0x39)))
        lo := add(lo, shl(mul(8, j), slice))
        input := shr(4, input)
      }
      for {
        let k := 0
      } lt(k, 32) {
        k := add(k, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        if gt(slice, 0x39) {
          slice := add(slice, 39)
        }
        hi := add(hi, shl(mul(8, k), slice))
        input := shr(4, input)
      }

      let stringLen := mload(stringPtr)

      // mstore(add(stringPtr, add(stringLen, 0x20)), '0x')
      mstore(add(stringPtr, add(stringLen, 0x20)), hi)
      mstore(add(stringPtr, add(stringLen, 0x40)), lo)
      mstore(stringPtr, add(stringLen, 0x40))
    }
  }

  function appendAddress(address input, bytes32 stringPtr) internal pure {
    assembly {
      let hi
      let lo
      for {
        let j := 0
      } lt(j, 8) {
        j := add(j, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        slice := add(slice, mul(39, gt(slice, 0x39)))
        lo := add(lo, shl(mul(8, j), slice))
        input := shr(4, input)
      }

      lo := shl(192, lo)
      for {
        let k := 0
      } lt(k, 32) {
        k := add(k, 0x01)
      } {
        let slice := add(0x30, and(input, 0xf))
        if gt(slice, 0x39) {
          slice := add(slice, 39)
        }
        hi := add(hi, shl(mul(8, k), slice))
        input := shr(4, input)
      }

      let stringLen := mload(stringPtr)

      mstore(add(stringPtr, add(stringLen, 0x20)), "0x")
      mstore(add(stringPtr, add(stringLen, 0x22)), hi)
      mstore(add(stringPtr, add(stringLen, 0x42)), lo)
      mstore(stringPtr, add(stringLen, 42))
    }
  }

  function appendUint(uint input, bytes32 stringPtr) internal pure {
    assembly {
      // Clear out some low bytes
      let result := mload(0x40)
      if lt(result, 0x200) {
        result := 0x200
      }
      mstore(add(result, 0xa0), mload(0x40))
      mstore(add(result, 0xc0), mload(0x60))
      mstore(add(result, 0xe0), mload(0x80))
      mstore(add(result, 0x100), mload(0xa0))
      mstore(add(result, 0x120), mload(0xc0))
      mstore(add(result, 0x140), mload(0xe0))
      mstore(add(result, 0x160), mload(0x100))
      mstore(add(result, 0x180), mload(0x120))
      mstore(add(result, 0x1a0), mload(0x140))

      // Store lookup table that maps an integer from 0 to 99 into a 2-byte ASCII equivalent
      mstore(
        0x00,
        0x0000000000000000000000000000000000000000000000000000000000003030
      )
      mstore(
        0x20,
        0x3031303230333034303530363037303830393130313131323133313431353136
      )
      mstore(
        0x40,
        0x3137313831393230323132323233323432353236323732383239333033313332
      )
      mstore(
        0x60,
        0x3333333433353336333733383339343034313432343334343435343634373438
      )
      mstore(
        0x80,
        0x3439353035313532353335343535353635373538353936303631363236333634
      )
      mstore(
        0xa0,
        0x3635363636373638363937303731373237333734373537363737373837393830
      )
      mstore(
        0xc0,
        0x3831383238333834383538363837383838393930393139323933393439353936
      )
      mstore(
        0xe0,
        0x3937393839390000000000000000000000000000000000000000000000000000
      )

      // Convert integer into string slices
      function slice(v) -> y {
        y := add(
          add(
            add(
              add(
                and(mload(shl(1, mod(v, 100))), 0xffff),
                shl(16, and(mload(shl(1, mod(div(v, 100), 100))), 0xffff))
              ),
              add(
                shl(32, and(mload(shl(1, mod(div(v, 10000), 100))), 0xffff)),
                shl(48, and(mload(shl(1, mod(div(v, 1000000), 100))), 0xffff))
              )
            ),
            add(
              add(
                shl(
                  64,
                  and(mload(shl(1, mod(div(v, 100000000), 100))), 0xffff)
                ),
                shl(
                  80,
                  and(mload(shl(1, mod(div(v, 10000000000), 100))), 0xffff)
                )
              ),
              add(
                shl(
                  96,
                  and(mload(shl(1, mod(div(v, 1000000000000), 100))), 0xffff)
                ),
                shl(
                  112,
                  and(mload(shl(1, mod(div(v, 100000000000000), 100))), 0xffff)
                )
              )
            )
          ),
          add(
            add(
              add(
                shl(
                  128,
                  and(
                    mload(shl(1, mod(div(v, 10000000000000000), 100))),
                    0xffff
                  )
                ),
                shl(
                  144,
                  and(
                    mload(shl(1, mod(div(v, 1000000000000000000), 100))),
                    0xffff
                  )
                )
              ),
              add(
                shl(
                  160,
                  and(
                    mload(shl(1, mod(div(v, 100000000000000000000), 100))),
                    0xffff
                  )
                ),
                shl(
                  176,
                  and(
                    mload(shl(1, mod(div(v, 10000000000000000000000), 100))),
                    0xffff
                  )
                )
              )
            ),
            add(
              add(
                shl(
                  192,
                  and(
                    mload(shl(1, mod(div(v, 1000000000000000000000000), 100))),
                    0xffff
                  )
                ),
                shl(
                  208,
                  and(
                    mload(
                      shl(1, mod(div(v, 100000000000000000000000000), 100))
                    ),
                    0xffff
                  )
                )
              ),
              add(
                shl(
                  224,
                  and(
                    mload(
                      shl(1, mod(div(v, 10000000000000000000000000000), 100))
                    ),
                    0xffff
                  )
                ),
                shl(
                  240,
                  and(
                    mload(
                      shl(1, mod(div(v, 1000000000000000000000000000000), 100))
                    ),
                    0xffff
                  )
                )
              )
            )
          )
        )
      }

      mstore(0x100, 0x00)
      mstore(0x120, 0x00)
      mstore(0x140, slice(input))
      input := div(input, 100000000000000000000000000000000)
      if input {
        mstore(0x120, slice(input))
        input := div(input, 100000000000000000000000000000000)
        if input {
          mstore(0x100, slice(input))
        }
      }

      function getMsbBytePosition(inp) -> y {
        inp := sub(
          inp,
          0x3030303030303030303030303030303030303030303030303030303030303030
        )
        let v := and(
          add(
            inp,
            0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
          ),
          0x8080808080808080808080808080808080808080808080808080808080808080
        )
        v := or(v, shr(1, v))
        v := or(v, shr(2, v))
        v := or(v, shr(4, v))
        v := or(v, shr(8, v))
        v := or(v, shr(16, v))
        v := or(v, shr(32, v))
        v := or(v, shr(64, v))
        v := or(v, shr(128, v))
        y := mul(
          iszero(iszero(inp)),
          and(
            div(
              0x201f1e1d1c1b1a191817161514131211100f0e0d0c0b0a090807060504030201,
              add(shr(8, v), 1)
            ),
            0xff
          )
        )
      }

      let len := getMsbBytePosition(mload(0x140))
      if mload(0x120) {
        len := add(getMsbBytePosition(mload(0x120)), 32)
        if mload(0x100) {
          len := add(getMsbBytePosition(mload(0x100)), 64)
        }
      }

      let currentStringLength := mload(stringPtr)

      let writePtr := add(stringPtr, add(currentStringLength, 0x20))

      let offset := sub(96, len)
      // mstore(result, len)
      mstore(writePtr, mload(add(0x100, offset)))
      mstore(add(writePtr, 0x20), mload(add(0x120, offset)))
      mstore(add(writePtr, 0x40), mload(add(0x140, offset)))

      // // update length
      mstore(stringPtr, add(currentStringLength, len))

      mstore(0x40, mload(add(result, 0xa0)))
      mstore(0x60, mload(add(result, 0xc0)))
      mstore(0x80, mload(add(result, 0xe0)))
      mstore(0xa0, mload(add(result, 0x100)))
      mstore(0xc0, mload(add(result, 0x120)))
      mstore(0xe0, mload(add(result, 0x140)))
      mstore(0x100, mload(add(result, 0x160)))
      mstore(0x120, mload(add(result, 0x180)))
      mstore(0x140, mload(add(result, 0x1a0)))
    }
  }

  function initErrorPtr() internal pure returns (bytes32, bytes32) {
    bytes32 mPtr;
    bytes32 errorPtr;
    assembly {
      mPtr := mload(0x40)
      if lt(mPtr, 0x200) {
        // our uint -> base 10 ascii method requires about 0x200 bytes of mem
        mPtr := 0x200
      }
      mstore(0x40, add(mPtr, 0x1000)) // let's reserve a LOT of memory for our error string.
      mstore(
        mPtr,
        0x08c379a000000000000000000000000000000000000000000000000000000000
      )
      mstore(add(mPtr, 0x04), 0x20)
      mstore(add(mPtr, 0x24), 0)
      errorPtr := add(mPtr, 0x24)
    }

    return (mPtr, errorPtr);
  }
}
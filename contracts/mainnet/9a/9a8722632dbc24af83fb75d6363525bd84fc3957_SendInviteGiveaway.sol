/**
 *Submitted for verification at polygonscan.com on 2022-02-19
*/

// SPDX-License-Identifier: MIT

// This contract for CorianderDAO.eth Invite Giveaway

/**

Join CorianderDAO.eth >> https://discord.gg/mPFb9cHdSK

一個新的潛力項目，每天送 20 USDC 不手軟，目前人還很少，非常好抽，
還有很新穎的賦能模式，養成系的項目，讓大家一起建設一個新世界～～

加入連結：https://discord.gg/mPFb9cHdSK

E-mail: [email protected]

今日起我們將每天抽出 10 USDC，每邀請 5 人，每天都能夠獲取一次抽獎資格，
邀請 10 人每天有 2 次，邀請 15 人每天則有 3 次 ... 以此類推
（邀請人數可累計，過去邀請紀錄也算）。

邀請人數足夠之後請於每日台北時間 18:00 前填寫此表單才能
參加當日之抽獎（表單不一定要每天填，但如需更新邀請人數則需再填一次才會生效）

https://forms.gle/Svfr7eZjTDNEcPFU6

獎項我們會在每天台北時間 23:59 前透過智能合約抽出 

另外，每日累積邀請人數前十名我們還會在額外每天
再各送出 1 USDC（連續 30 天前十名就能拿到 30 USDC）

Roadmap 更新 2022.02.19

1.    我們預計三月發行我們的DAO會員NFT，用於募集DAO所需的初始資金。

2.    之後會發行 Coriander Coin其中50% 空投給會員 NFT 持有者，剩下 50% 將定期（暫定每季）空投給 Coriander Coin 持有者。

3.    作為CorianderDAO發展的第一步，我們將推出農地 NFT，會員 NFT 持有者將可優先認購，認購後將成為第一批進 Coriander World 開墾的農民與地主，而每塊農地將可切分為100塊種植地。

4.    每塊種植地可用於種植作物，種植作物須每天澆水、施肥照顧，經過一定時間成熟過後可換取收益。

5.    農地的地主可將其農地出租給其他地主後定期收取租金，也能自己種植作物。

6.    DAO 收益（包含廣告、NFT項目合作、NFT 版費（Royalty Fee） … 組織相關之收益）扣除成本之後80% 回饋給會員NFT 及 Coriander Coin 持有人，20% 捐贈給慈善機構。

7.    我們目前正在徵求商家一起合作，合作商家有機會認購更多我們的會員 NFT，進一步參與 Coriander World 的建設，並得到更多的曝光度，有興趣的可以到 🎗-合作交流討論區  交流或是 E-mail 到 [email protected] ，我們將有專人與您洽談。 

 */

pragma solidity ^0.8.11;

interface ERC20_Token {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract SendInviteGiveaway {
    ERC20_Token public usdcToken;
    address public contractOwner;

    // address public nftContractAddr;
    address[] public inviteGiveawayAddr;
    address[] public top10GiveawayAddr;

    mapping(address => uint) public stakingBalance;

    constructor() {
        contractOwner = msg.sender;
        usdcToken = ERC20_Token(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        // usdcToken.approve(msg.sender, 5);
    }

    function unstakeTokens(uint _amount) public {
        require(contractOwner==msg.sender, "Permission Denied");
        usdcToken.transfer(msg.sender, _amount);
    }

    function addGiveawayAddress(address participantAddr, uint256 numberOfChance) public {
        require(contractOwner==msg.sender, "Permission Denied");
        for (uint i = 0; i < numberOfChance; i++) {
            inviteGiveawayAddr.push(participantAddr);
        }
    }

    function addTop10Address(address participantAddr) public {
        require(contractOwner==msg.sender, "Permission Denied");
        top10GiveawayAddr.push(participantAddr);
    }

    function removeTop10Address(uint256 index) public {
        require(contractOwner==msg.sender, "Permission Denied");
        delete top10GiveawayAddr[index];
    }

    function sendRandomGiveaway(uint256 _amount) public {
        require(contractOwner==msg.sender, "Permission Denied");
        uint256 winnerIndex = random(inviteGiveawayAddr.length);
        usdcToken.transfer(inviteGiveawayAddr[winnerIndex], _amount*10**6);
    }

    function sendTop10Giveaway(uint256 _amount) public {
        require(contractOwner==msg.sender, "Permission Denied");
        
        for (uint i = 0; i < inviteGiveawayAddr.length; i++) {
            usdcToken.transfer(top10GiveawayAddr[i], _amount*10**6);
        }
    }

    function random(uint256 _len) private view returns (uint256) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%_len);
    }
}
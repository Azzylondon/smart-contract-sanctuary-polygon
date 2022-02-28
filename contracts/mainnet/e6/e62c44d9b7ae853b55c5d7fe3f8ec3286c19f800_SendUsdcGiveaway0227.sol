/**
 *Submitted for verification at polygonscan.com on 2022-02-28
*/

// SPDX-License-Identifier: MIT

// This contract for CorianderDAO.eth Invite Giveaway

// UTC+8 Feb-27, 2022 Giveaway Contract

/**

Join CorianderDAO.eth >> https://discord.gg/mPFb9cHdSK

一個新的潛力項目，
還有很新穎的賦能模式，養成系的項目，讓大家一起建設一個新世界～～

加入連結：https://discord.gg/mPFb9cHdSK

E-mail: [email protected]

獎勵規則如下：
1️. 加入 CorianderDAO 所有人皆可於每日抽 1 USDC，每天抽出 5 位，共 5 USDC。
2️. 邀請 8 人即可成為 @外交小尖兵，每日可以抽 5 USDC，每天抽出 1 位。 
3️. 邀請 20 人即可成為 @外交大使 ，每日可以抽 10 USDC，每天抽出 1 位。

Roadmap 更新 2022.02.23

1.    我們預計三月發行我們的DAO會員NFT，用於募集DAO所需的初始資金。

2.    之後會發行 Coriander Coin其中50% 空投給會員 NFT 持有者，剩下 50% 將定期（暫定每季）空投給 Coriander Coin 持有者。

3.    作為CorianderDAO發展的第一步，我們將推出農地 NFT，會員 NFT 持有者將可優先認購，認購後將成為第一批進 Coriander World 開墾的農民與地主，而每塊農地將可切分為100塊種植地。

4.    每塊種植地可用於種植作物，種植作物須每天澆水、施肥照顧，經過一定時間成熟過後可換取收益。

5.    農地的地主可將其農地出租給其他地主後定期收取租金，也能自己種植作物。

6.    DAO 收益（包含廣告、NFT項目合作、NFT 版費（Royalty Fee） … 組織相關之收益）扣除成本之後80% 回饋給會員NFT 及 Coriander Coin 持有人，20% 捐贈給慈善機構。

7.    我們目前正在徵求商家一起合作，合作商家有機會認購更多我們的會員 NFT，進一步參與 Coriander World 的建設，並得到更多的曝光度，有興趣的可以到 🎗-合作交流討論區  交流或是 E-mail 到 [email protected] ，我們將有專人與您洽談。 

 */

pragma solidity ^0.8.12;

interface ERC20_Token {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract SendUsdcGiveaway0227 {
    ERC20_Token public usdcToken;
    address public contractOwner;
    
    constructor() {
        contractOwner = msg.sender;
        usdcToken = ERC20_Token(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    }

    function unstakeTokens(uint _amount) public {
        require(contractOwner==msg.sender, "Permission Denied");
        usdcToken.transfer(msg.sender, _amount);
    }

    function sendGiveaway() public {
        require(contractOwner==msg.sender, "Permission Denied");
        sendUsdc(0xb694a38be2a9FDd8bb199f3158b9C701747A0a8a, 1); // 5條貓悟#4347, 1U .
        sendUsdc(0xdE2a649A23AFC45A55A4d68B7CFDd683279b62f6, 1); // 法鬥 | Wilson420.eth | PGSF#8792, 1U .
        sendUsdc(0x2fEf657Cb9f666c15DC37A1C9aEDc6171F46b48D, 1); // SIANG | MetaStore#2642, 1U
        // sendUsdc(NULL, 1); // twlo#3117, 1U
        sendUsdc(0x92c915950336FC0a25112C679992bE93421dBfCc, 1); // BlackCoffee#4789, 1U .
        sendUsdc(0x9dD0E08691fC9E8B9FaE57fEe5adA2fCD8E19A5f, 5); // ouo#4886, 5U .
        sendUsdc(0xdE2a649A23AFC45A55A4d68B7CFDd683279b62f6, 10); // 法鬥 | Wilson420.eth | PGSF#8792, 10U .
    }

    function sendUsdc(address recipientAddr, uint _amount) public {
        require(contractOwner==msg.sender, "Permission Denied");
        usdcToken.transfer(recipientAddr, _amount*10**6);
    }
}
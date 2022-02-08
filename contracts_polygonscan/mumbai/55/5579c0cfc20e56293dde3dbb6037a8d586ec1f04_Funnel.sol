/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//=====================--------- DEPLOYMENT TO-DOS:  ----------=====================

//TODO: implement tests in Hardhat.
//TODO: DEPLOY CONTRACT USING PROXY PATTERN.

//=====================--------- ITERATION TO-DOS:  ----------=====================

//TODO: implement protocol for refunds
//TODO: implement protocol for affiliate payments
contract Funnel {
    //=====================--------- EVENTS  ----------=====================

    event PaymentMade(address from, address storeAddress, string productName);

    //=====================--------- DATA STRUCTURES  ----------=====================
    struct Product {
        string _productName;
        uint256 _price;
    }
    //TODO: consider adding store name in bytes32?
    struct Store {
        //bytes32 _storeName;
        address _storeOwner;
        address payable _storeAddress;
        uint256 _storeTotalValue;
        Product[] _storeProducts;
    }

    struct Affiliate {
        address payable _affiliateAddress;
        uint256 _commision;
    }

    //=====================--------- STATE VARIABLES ----------=====================

    uint256 private noOfStores;
    mapping(address => Store) private stores;
    mapping(address => bool) private isAdmin;

    //=====================--------- MODIFIERS ----------=====================

    //TODO: consider possibility of allowing for there to be multiple owners for a store?
    modifier onlyStoreOwner(address storeAddress) {
        //check that caller is owner of specific store.
        require(
            stores[storeAddress]._storeOwner == msg.sender,
            "not store owner"
        );
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "not admin");
        _;
    }

    //=====================--------- STORE FUNCTIONS ----------=====================
    constructor() {
        isAdmin[msg.sender] = true;
    }

    function totalStores() public view returns (uint256) {
        return noOfStores;
    }

    function registerStore(address payable storeAddress)
        external
        onlyAdmin
        returns (uint256)
    {
        Store storage store = stores[storeAddress];
        store._storeOwner = msg.sender;
        store._storeAddress = storeAddress;
        store._storeTotalValue = 0;

        uint256 storeIndex = totalStores();
        noOfStores++;

        return storeIndex;
    }

    function updateStoreAddress(
        address storeAddress,
        address payable newStoreAddress
    ) external onlyStoreOwner(storeAddress) {
        Store storage store = stores[newStoreAddress];
        store._storeAddress = newStoreAddress;
        store._storeTotalValue = stores[storeAddress]._storeTotalValue;
        store._storeOwner = stores[storeAddress]._storeOwner;
        store._storeProducts = stores[storeAddress]._storeProducts;

        delete stores[storeAddress];
    }

    //TODO: consider making the resetrictions on this function more robust: multiple admins required?
    function removeStore(address storeAddress) public onlyAdmin {
        //currently only one admin
        //currently only they can remove store.
        delete stores[storeAddress];
    }

    function getStore(address storeAddress) external view returns (Store memory) {
        return stores[storeAddress];
    }

    //=====================--------- TRANSACTIONAL FUNCTIONS ----------=====================

    //TODO: allow payments to be made for multiple products, and not just one.
    function makePayment(
        address payable storeAddress,
        string memory productName
    ) external payable returns (bool) {
        uint256 productIndex = getProductIndex(storeAddress, productName);
        uint256 price = stores[storeAddress]
            ._storeProducts[productIndex]
            ._price;
        require(msg.value == price, "Pay the right price");

        // address payable storeAddress = stores[storeAddress]._storeAddress;
        storeAddress.transfer(msg.value);
        stores[storeAddress]._storeTotalValue += msg.value;

        emit PaymentMade(msg.sender, storeAddress, productName);

        return true;
    }

    //=====================--------- PRODUCT FUNCTIONS ----------=====================

    function totalProducts(address storeAddress) public view returns (uint256) {
        return stores[storeAddress]._storeProducts.length;
    }

    function getProducts(address storeAddress)
        external
        view
        returns (Product[] memory)
    {
        return stores[storeAddress]._storeProducts;
    }

    function createProduct(
        address storeAddress,
        string memory productName,
        uint256 price
    ) external onlyStoreOwner(storeAddress) {
        Product memory product = Product(productName, price);

        stores[storeAddress]._storeProducts.push(product);
    }

    function removeProduct(address storeAddress, string memory productName)
        external
        onlyStoreOwner(storeAddress)
    {
        uint256 productIndex = getProductIndex(storeAddress, productName);
        Product[] storage products = stores[storeAddress]._storeProducts;

        products[productIndex] = products[products.length - 1];
        products.pop();
    }

    //helper function for `removeProduct`
    function getProductIndex(address storeAddress, string memory productName)
        internal
        view
        returns (uint256)
    {
        for (uint256 i; i < stores[storeAddress]._storeProducts.length; i++) {
            if (
                keccak256(
                    bytes(stores[storeAddress]._storeProducts[i]._productName)
                ) == keccak256(bytes(productName))
            ) {
                return i;
            }
        }

        revert("Product not found in store");
    }

    function getProductPrice(address storeAddress, string memory productName)
        external
        view
        returns (uint256)
    {
        uint256 productIndex = getProductIndex(storeAddress, productName);
        return stores[storeAddress]._storeProducts[productIndex]._price;
    }

    function updateProductPrice(
        address storeAddress,
        string memory productName,
        uint256 price
    ) external onlyStoreOwner(storeAddress) {
        uint256 productIndex = getProductIndex(storeAddress, productName);
        stores[storeAddress]._storeProducts[productIndex]._price = price;
    }
}
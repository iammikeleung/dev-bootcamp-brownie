pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";



contract PriceContract is ChainlinkClient {
  
    AggregatorV3Interface internal priceFeed;
    
    uint256 public volume;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    bool public priceFeedGreater; 
    int256 public storedPrice;



    
      constructor(address _oracle, string memory _jobId, uint256 _fee, address _link, address AggregatorAddress) public {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        // oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        // jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
        // fee = 0.1 * 10 ** 18; // 0.1 LINK
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _fee;

        priceFeed = AggregatorV3Interface(AggregatorAddress);
    
    }

    function getPriceFeedGreater() public view returns (bool) {
        return priceFeedGreater;
    }

    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function requestPriceData()  public returns (bytes32) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=USD");
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"BTC":
        //    {"USD":
        //     {
        //      "price": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "RAW.BTC.USD.PRICE");
        

        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

      /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId)
    {
        storedPrice = _price;
       if (int256(getLatestPrice() > int256(storedPrice)){
           priceFeedGreater = true;
       } else {
           priceFeedGreater = false;
       }
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}
    
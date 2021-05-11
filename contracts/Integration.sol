pragma solidity ^0.6.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/libraries/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract UniswapIntegrationAgent {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniV2Router;
    IUniswapV2Factory public uniV2Factory;

    constructor(address _uniswapV2Router02) public {
        uniV2Router = IUniswapV2Router02(_uniswapV2Router02);
        uniV2Factory = IUniswapV2Factory(uniV2Router.factory());
    }

    event Swapp(uint256[] amounts);
    event Swap(
        address indexed user,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event AddLiquidity(
        address indexed user,
        address indexed tokanA,
        address indexed tokenB,
        uint256 addedAmountA,
        uint256 addedAmountB,
        uint256 liquidityPoolTokenAmount
    );
    event RemoveLiquidity(
        address indexed user,
        address indexed tokanA,
        address indexed tokenB,
        uint256 addedAmountA,
        uint256 addedAmountB,
        uint256 liquidityPoolTokenAmount
    );

    //Add Liquidity Function
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 tokenAmountA,
        uint256 tokenAmountB
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        IERC20(tokenA).transferFrom(msg.sender, address(this), tokenAmountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), tokenAmountB);
        IERC20(tokenA).approve(address(uniV2Router), tokenAmountA);
        IERC20(tokenB).approve(address(uniV2Router), tokenAmountB);

        (amountA, amountB, liquidity) = uniV2Router.addLiquidity(
            tokenA,
            tokenB,
            tokenAmountA,
            tokenAmountB,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        IERC20(tokenA).transfer(msg.sender, (tokenAmountA.sub(amountA)));
        IERC20(tokenB).transfer(msg.sender, (tokenAmountB.sub(amountB)));
        emit AddLiquidity(
            msg.sender,
            tokenA,
            tokenB,
            amountA,
            amountB,
            liquidity
        );
    }

    //addLiquidityETH Function
    function addLiquidityETH(address token, uint256 tokenAmount)
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
        IERC20(token).approve(address(uniV2Router), tokenAmount);

        (amountToken, amountETH, liquidity) = uniV2Router.addLiquidityETH{
            value: msg.value
        }(token, tokenAmount, 0, 0, msg.sender, block.timestamp);

        IERC20(token).transfer(msg.sender, (tokenAmount.sub(amountToken)));
        msg.sender.transfer(msg.value.sub(amountETH));
        emit AddLiquidity(
            msg.sender,
            token,
            uniV2Router.WETH(),
            amountToken,
            amountETH,
            liquidity
        );
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external returns (uint256 amountA, uint256 amountB) {
        address lpToken = uniV2Factory.getPair(tokenA, tokenB);
        IUniswapV2Pair(lpToken).transferFrom(
            msg.sender,
            address(this),
            liquidity
        );
        IUniswapV2Pair(lpToken).approve(address(uniV2Router), liquidity);

        (amountA, amountB) = uniV2Router.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            block.timestamp
        );
        emit RemoveLiquidity(
            msg.sender,
            tokenA,
            tokenB,
            amountA,
            amountB,
            liquidity
        );
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to
    ) external returns (uint256 amountToken, uint256 amountETH) {
        address lpToken = uniV2Factory.getPair(token, uniV2Router.WETH());
        require(lpToken != address(0), "No LP token found");
        IUniswapV2Pair(lpToken).transferFrom(
            msg.sender,
            address(this),
            liquidity
        );
        IUniswapV2Pair(lpToken).approve(address(uniV2Router), liquidity);
        (amountToken, amountETH) = uniV2Router.removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            block.timestamp
        );
        emit RemoveLiquidity(
            msg.sender,
            token,
            uniV2Router.WETH(),
            amountToken,
            amountETH,
            liquidity
        );
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB) {
        address lpToken = uniV2Factory.getPair(tokenA, tokenB);
        IUniswapV2Pair(lpToken).transferFrom(
            msg.sender,
            address(this),
            liquidity
        );
        (amountA, amountB) = uniV2Router.removeLiquidityWithPermit(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline,
            approveMax,
            v,
            r,
            s
        );
        //emit RemoveLiquidity(msg.sender, tokenA, tokenB, amountA, amountB, liquidity);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = uniV2Router.removeLiquidityETHWithPermit(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline,
            approveMax,
            v,
            r,
            s
        );
        //emit RemoveLiquidity(msg.sender, token, uniV2Router.WETH(), amountToken, amountETH, liquidity);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(address(uniV2Router), amountIn);

        amounts = uniV2Router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );
        emit Swapp(amounts);
        emit Swap(msg.sender, path[0], path[1], amountIn, amounts[1]);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path
    ) external returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountInMax);
        IERC20(path[0]).approve(address(uniV2Router), amountInMax);

        amounts = uniV2Router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            msg.sender,
            block.timestamp
        );
        IERC20(path[0]).transfer(msg.sender, (amountInMax.sub(amounts[0])));
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]);
    }

    function swapExactETHForTokens(address[] calldata path)
        external
        payable
        returns (uint256[] memory amounts)
    {
        require(path[0] == uniV2Router.WETH(), "Incorrect Path");
        amounts = uniV2Router.swapExactETHForTokens{value: msg.value}(
            0,
            path,
            msg.sender,
            block.timestamp
        );
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path
    ) external returns (uint256[] memory amounts) {
        require(path[path.length - 1] == uniV2Router.WETH(), "Incorrect Path");
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountInMax);
        IERC20(path[0]).approve(address(uniV2Router), amountInMax);

        amounts = uniV2Router.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            payable(msg.sender),
            block.timestamp
        );

        IERC20(path[0]).transfer(msg.sender, (amountInMax.sub(amounts[0])));
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external returns (uint256[] memory amounts) {
        require(path[path.length - 1] == uniV2Router.WETH(), "Incorrect Path");
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(address(uniV2Router), amountIn);

        amounts = uniV2Router.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            payable(msg.sender),
            block.timestamp
        );
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]);
    }

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path)
        external
        payable
        returns (uint256[] memory amounts)
    {
        require(path[0] == uniV2Router.WETH(), "Incorrect Path");

        amounts = uniV2Router.swapETHForExactTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            block.timestamp
        );
        msg.sender.transfer(msg.value.sub(amounts[0]));
        emit Swapp(amounts);
        emit Swap(msg.sender, path[0], path[1], amounts[0], amounts[1]);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(address(uniV2Router), amountIn);
        uniV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable {
        uniV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(amountOutMin, path, to, deadline);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(path[path.length - 1] == uniV2Router.WETH(), "Incorrect Path");
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(address(uniV2Router), amountIn);
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    receive() external payable {}
}

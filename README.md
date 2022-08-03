# LotteryManager合约接口

1. createTableIfNecessary，创建桌子

   ```solidity
   function createTableIfNecessary(
       address creator, //创建者
       uint256 amount, //金额
       uint256 minPPL,//最小参加人数
           uint256 maxPPL, //最大参加人数
           uint256 coolDownTime, //游戏冷却时间
           uint256 gameTime,//游戏开始时间
           uint256 bankerCommission, //庄家佣金比例，按万分之一计算
           uint256 referralCommission, //推荐佣金比例，按万分之一计算
           address bankerWallet //庄家钱包
   )
   external 
   onlyManagerOwner 
   payable 
   returns (string memory hashString);
       
   event CreateTableIfNecessary(
       string hash//table的hash
   )
    
   ```
   
2. joinTableV2，玩家加入游戏，需要根据玩家`` 下注数*桌子金额 ``获取approve权限

   ```solidity
   function joinTableV2(
       uint256 count, //下注数量
       uint256 number, //下注号码
       string memory hash//table的hash
   )
       external 
       payable 
       returns (bool result);
   
   event BankerCommission(
       address player, //玩家
       address banker, //庄家
       uint256 amount //佣金
   );
   
   event ReferCommission(
       address player, //玩家
       address refer, //推荐人
       uint256 amount //佣金
   );
   
   ```

3. editTable，修改桌子参数，在下一次游戏开奖后生效

   ```solidity
   function editTable(
       string memory hashString, //table的hash
       ILotteryTable.TableInfo memory tableInfo
   ) 
   external 
   onlyManagerOwner
   
   struct ILotteryTable.TableInfo {
     address creator;//创建者
     uint256 amount;//金额
     uint256 minPPL;//最小参加人数
     uint256 maxPPL;//最大参加人数
     uint256 coolDownTime;//游戏冷却时间
     uint256 gameTime;//游戏开始时间
     uint256 bankerCommission;//庄家佣金比例，按万分之一计算
     uint256 referralCommission;//推荐佣金比例，按万分之一计算
     address bankerWallet;//庄家钱包
   }
   ```

   1. startRoundV2, 游戏开奖

      ```solidity
      function startRoundV2(
          string memory hash //table的hash
      ) 
      external 
      onlyManagerOwner 
      payable
      returns (bool);
   
      event StartRound(
              string hash,//table的hash
              uint256 round,//第几轮
              uint256 poolAmount,//奖金池大小
              uint256 roundNumber,//开奖结果
              address[] roundWinnerArray,//赢家
              uint256[] winnerCount,//赢家下注数量
              int256[] rewards,//玩家本局输赢金额
              address[] allPlayers,//所有玩家
              uint256[] numbers,//玩家下注号码
              uint256[] counts//玩家下注数量
      );
   
      event EditTable(
          string beforeHash, //修改前的table hash
          string newHash //修改后的table hash
      );
      ```

4. referral，邀请

   ```solidity
   function referral(
       address a, //被邀请人
       address b	//邀请人
   ) 
   external 
   onlyManagerOwner 
   returns (bool result);
   ```

5. holdingTicket，查询当前游戏情况

   ```solidity
   function holdingTicket(
       string memory hash //table hash
   ) 
   external
   view
   returns(
        string memory tableHash, //hash
        uint256 round, //第几局
        address[] memory players, //所有玩家
        uint256[] memory numbers, //玩家下注号码
        uint256[] memory counts //玩家下注数量
   );
   
   
   ```

   


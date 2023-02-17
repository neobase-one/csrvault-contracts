// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Turnstile {
	function register(address) external returns(uint256);
	function safeTransferFrom(address, address, uint256) external;
	function withdraw(uint256, address payable, uint256) external returns(uint256);
}

contract CSRVault {
	bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

	Turnstile turnstile;
	mapping(uint256 => address) owners;
	mapping(uint256 => address payable) feeRecipients;

	event DepositNFT(uint256 _tokenId, address _feeRecipient, address _sender);
	event WithdrawNFT(uint256 _tokenId, address _to);
	event UpdateFeeRecipient(uint256 _tokenId, address _feeRecipient);
	event WithdrawFee(uint256 _tokenId, uint256 _amount);

	constructor(address _turnstileAddress){
		turnstile = Turnstile(_turnstileAddress);
		turnstile.register(tx.origin);
	}

	function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return _ERC721_RECEIVED;
  }

  function depositNFT(uint256 _tokenId, address payable _feeRecipient) external {
    turnstile.safeTransferFrom(msg.sender, address(this), _tokenId);
    owners[_tokenId] = msg.sender;
		feeRecipients[_tokenId] = _feeRecipient;
    emit DepositNFT(_tokenId, _feeRecipient, msg.sender);
  }

	function withdrawNFT(uint256 _tokenId, address _to) external {
		require(owners[_tokenId] == msg.sender, "unauthorized");
    delete owners[_tokenId];
		delete feeRecipients[_tokenId];
		turnstile.safeTransferFrom(address(this), _to, _tokenId);
    emit WithdrawNFT(_tokenId, _to);
  }
	
	function updateFeeRecipient(uint256 _tokenId, address payable _feeRecipient) external {
		require(owners[_tokenId] == msg.sender, "unauthorized");
		feeRecipients[_tokenId] = _feeRecipient;
		emit UpdateFeeRecipient(_tokenId, _feeRecipient);	
	}

	function withdrawFee(uint256 _tokenId,uint256 _amount) external {
		uint256 amount = turnstile.withdraw(_tokenId, feeRecipients[_tokenId], _amount);
		emit WithdrawFee(_tokenId, amount);
	}
}

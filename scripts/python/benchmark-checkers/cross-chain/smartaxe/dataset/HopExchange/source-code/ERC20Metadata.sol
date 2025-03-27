// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20MetadataStorage} from './ERC20MetadataStorage.sol';
import {IERC20Metadata} from './IERC20Metadata.sol';

/**
 * @title ERC20 metadata extensions
 */
abstract contract ERC20Metadata is IERC20Metadata {
  /**
   * @inheritdoc IERC20Metadata
   */
  function name () virtual override public view returns (string memory) {
    return ERC20MetadataStorage.layout().name;
  }

  /**
   * @inheritdoc IERC20Metadata
   */
  function symbol () virtual override public view returns (string memory) {
    return ERC20MetadataStorage.layout().symbol;
  }

  /**
   * @inheritdoc IERC20Metadata
   */
  function decimals () virtual override public view returns (uint8) {
    return ERC20MetadataStorage.layout().decimals;
  }
}
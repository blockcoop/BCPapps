// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Base64 } from "./libraries/Base64.sol";

contract TokenURI {
    string internal constant svgPartOne = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base {font-family:Sans,Arial; font-weight: bold; }</style><rect x='5' y='5' rx='20' ry='20' width='340' height='340' style='fill:#FFFFFF;stroke:#EB3933;stroke-width:5;stroke-opacity:0.9' /><text x='50%' y='40' class='base' text-anchor='middle' fill='#8F8F8F' style='font-size: 11px;'>COOP NAME</text><text x='50%' y='70' class='base' fill='#000000' text-anchor='middle'>";

    string internal constant svgPartTwo = "</text><circle cx='50%' cy='190' r='80' stroke='#979797' stroke-width='1' fill='#D8D8D8' /><text x='50%' y='190' class='base' fill='#000000' dominant-baseline='middle' text-anchor='middle'>";

    function create(string memory name, string memory memberType) public pure returns (string memory) {
        string memory finalSvg = string(abi.encodePacked(svgPartOne, name, svgPartTwo, memberType, "</text></svg>"));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        name,
                        ' membership", "description": "',
                        memberType,
                        ' Membership card for ',
                        name,
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return finalTokenUri;
    } 
}
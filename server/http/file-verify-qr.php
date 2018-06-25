<?php
require('utils.php');
require('generation-pdf.php');
$loadConfig_result = loadConfig();
if (!$loadConfig_result[0]) {
    echo $loadConfig_result[1];
    exit(1);
}

DEFINE('SUBMIT_HASH', '0x708b34fe');

function uploadResult($isSuccess, $fileName, $typeText, $hash, $datetime_ts, $error, $debug = false)
{
    return json_encode([
        'fileName' => '/pdf/' . $fileName . '.pdf',
        'success' => $isSuccess,
        'typeText' => $typeText,
        'hash' => $hash,
        'datetime_ts' => $datetime_ts,
        'error' => $error,
        'debug' => $debug
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
}

/**
 * @param JsonRpc\Client $gethClient
 * @param string $hash
 * @return object
 */
function getBlockByHash(&$gethClient, $hash)
{
    $block = [];
    if ($gethClient->call('eth_getBlockByHash', [
        $hash,
        false
    ])) {
        /* Example object(stdClass)
        difficulty: "0x99379ead"
        extraData: "0xd783010700846765746887676f312e372e34856c696e7578"
        gasLimit: "0x665333"
        gasUsed: "0x3aa59"
        hash: "0xcb127b04b583a70919e1550fb49139586a5b6d02f0156f4464878201c3106989"
        logsBloom: "0x00000000000080000000000000000000000000080000000000000000400000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000020000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000800000000002000000000000100000000000000000000000000000"
        miner: "0x8c60d40a2e848251d139fc2b0b6b770bb3351ffd"
        mixHash: "0xfc438bb77786f3f5921343ecfc227a80461a8c9e6c5831ba5f3ceca8a7d3ab4b"
        nonce: "0x4fa8ce0eeb1c72cb"
        number: "0x1f4c1e"
        parentHash: "0x2b4bc64b05e67c5dedf646e3fa6e685175a93780af6b7dd138759d5e234c5ddf"
        receiptsRoot: "0x8c1f2693dd7cc19ea03235c1cd6312ce076101088db6b64814128009e1d076f6"
        sha3Uncles: "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347"
        size: "0x773"
        stateRoot: "0x991d6513378d8517860a3e06768292d99954d60bfebb06c9ff58e6851918fe47"
        timestamp: "0x5a07199a"
        totalDifficulty: "0x17b50790497fd8"
        transactions: (11) ["0x9ec75201bcd7dbea8898f82b7ba1bfb18c5d89e9b64feeee602060ef60da008b", "0xe43e32f2866d5cc53b4f24996d62d1dde11698d1b7867c4950cb6b5efd8de4a0", "0xb078678716ddf8a8873d64d3771ec3584bb29f59c56a6efc5019988b7733f8df", "0xfadd9dd5cef89da914bd0a02fa18dd2f1ac28b73d469088b503e8c97b3f7e8c4", "0x73dffe907111577b98b16733b51e0a2f350f67905c14d3eb30f2f3651f083b77", "0x60717d5fc26db71b6817b6db5a1bd112b0eada77eaefd1c2e5b94d401401b98b", "0xbb42cc66fe2d4ddcdf3bc2f3e5e18f2bd7c587c979bf75055312a1d21ade4bf3", "0x9381b9c011083a7e8030e2871fc13b2eac3d7bf51525227aa4f637db1a44f8db", "0x9a7c6953a42de9f6b6b6cf4a7d5834587a3001a8d21c3777eb49633d24b442dc", "0xd05f9167ba17253b1972c1bc5677d908a11586a9f1b0d26f77d4d7d9aaf77810", "0x509b34abb056cbde1244eec58e094511cecd48c14aac3594d5f4031001b0bfd4"]
        transactionsRoot: "0x0eebcecdbb90d7917d190a5491006e5bad2b465cd61e789e1ba4353950d407b5"
        uncles: []
         */
        $block = $gethClient->result;
    }
    return $block;
}

/**
 * @param string $file full path to temporary location of uploaded file
 * @param string $fileName original filename
 * @return array
 */
function worker($file, $fileName)
{
    $hash = hash_file('sha256', $file);
    $result = exec("searchqrcode -w 1000 $file --orig-file-name '$fileName' 2> /dev/null", $output, $return_code);

    if ($return_code !== 0) {
        return [
            'isSuccess' => false,
            'typeText' => '',
            'hash' => '0x' . $hash,
            'error' => 'wrong searchqrcode input file'
        ];
    }

    $qrcodeInfo = json_decode($result, true);

    if (!$qrcodeInfo || !isset($qrcodeInfo['txhash']) || !isset($qrcodeInfo['blockhash'])) {
        return [
            'isSuccess' => false,
            'typeText' => '',
            'hash' => '0x' . $hash,
            'error' => 'wrong searchqrcode result'
        ];
    }

    $gethClient = new JsonRpc\Client(GETH_NODE_URL);
    $params = [
        $qrcodeInfo['txhash']
    ];
    if ($gethClient->call('eth_getTransactionByHash', $params)) {
        /* EXAMPLE $gethClient->result
            object(stdClass)#6 (14) {
              ["blockHash"]=> string(66) "0x228fa0d54cc00dba260de045bddf5aae84c7e11f27a3f455959b73b257d299b4"
              ["blockNumber"]=> string(8) "0x1f4b86"
              ["from"]=> string(42) "0x42e1e53a644e3f8d5dc606c5104f6666163f2c76"
              ["gas"]=> string(7) "0xf4240"
              ["gasPrice"]=> string(10) "0xee6b2800"
              ["hash"]=> string(66) "0xc208cea8d09f1bf4d8625e653d4b5e387dabbb9a565c65f97a0698cd69168379"
              ["input"]=> string(10) "0x74305b38"
              ["nonce"]=> string(3) "0x3"
              ["to"]=> string(42) "0x675dfc2a32683bc4287ca6376a9613e0c68037fa"
              ["transactionIndex"]=> string(3) "0x3"
              ["value"]=> string(3) "0x0"
              ["v"]=> string(4) "0x1b"
              ["r"]=> string(66) "0x4e0cc00f7e782f1b45f9b53a810e211f82028288ccc35bd8957c11de958aa7d4"
              ["s"]=> string(65) "0x12f49c4ac822f7914a6fcdcca9d44e73fdfd4f5dfbab3e36abbdb0bca5c784c"
            }
            */
        if (substr($gethClient->result->blockHash, 0, 30) != $qrcodeInfo['blockhash']) {
            return [
                'isSuccess' => false,
                'typeText' => '',
                'hash' => '0x' . $hash,
                'error' => 'wrong block hash'
            ];
        }
        if ($gethClient->result->to !== CONTRACT_ADDRESS) {
            return [
                'isSuccess' => false,
                'typeText' => '',
                'hash' => '0x' . $hash,
                'error' => 'wrong contract'
            ];
        }
        if (substr($gethClient->result->input, 0, 10) != SUBMIT_HASH) {
            return [
                'isSuccess' => false,
                'typeText' => '',
                'hash' => '0x' . $hash,
                'error' => 'wrong submit hash input'
            ];
        }
        $inputStrLength = hexdec(substr($gethClient->result->input, 2 + (4 + 32) * 2, 64));
        $inputStrHex = substr($gethClient->result->input, 2 + (4 + 32 + 32) * 2, $inputStrLength * 2);
        $inputStr = hexToStr($inputStrHex);
        $block = getBlockByHash($gethClient, $gethClient->result->blockHash);
        $datetime_ts = hexdec($block->timestamp);

        generationPdfQr($fileName, $inputStr, '0x' . $hash, $datetime_ts);
        return [
            'fileName' => $fileName,
            'isSuccess' => true,
            'typeText' => $inputStr,
            'datetime_ts' => $datetime_ts,
            'hash' => '0x' . $hash,
            'error' => ''
        ];
    } else {
        return [
            'isSuccess' => false,
            'typeText' => '',
            'hash' => '0x' . $hash,
            'error' => $gethClient->error
        ];
    }
}

$file = '';
$fileName = '';
if (!empty($_FILES['file'])) {
    $file = $_FILES['file']['tmp_name'];
    $fileName = $_FILES['file']['name'];
} else if (isset($argv[1])) {
    $file = $argv[1];
}
$fileName = str_replace(" ", "_", $fileName);
$workerResult = worker($file, $fileName);
die(uploadResult($workerResult['isSuccess'], $workerResult['fileName'], $workerResult['typeText'], $workerResult['hash'], $workerResult['datetime_ts'], $workerResult['error']));



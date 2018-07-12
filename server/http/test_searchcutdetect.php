<?php
require('utils.php');
$loadConfig_result = loadConfig();
if (!$loadConfig_result[0]) {
    echo $loadConfig_result[1];
    exit(1);
}

define('GETLOGS_FILE_EVENT_ID', '0x461afacbe8920fcf3516d8b18e2634291cc96d0151ab7d324cca32fb77c44986');
define('USER_ADDRESS_FILTER', null);
define('EXAMPLE_FILE_HASH', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
define('TRANSACTIONBYHASH_CORRECT_INPUT', '0x74305b38');

if (@$_GET['TEST_SEARCHCUTDETECT_PASSWORD'] !== TEST_SEARCHCUTDETECT_PASSWORD) {
    echo 'please, send GET or configure config.json: TEST_SEARCHCUTDETECT_PASSWORD';
    exit(1);
}

/**
 * @param string $file
 * @param string $fileName
 * @return array
 */
function worker($file, $fileName)
{
    $validated = false;

    $cmd = "cutdetect $file --orig-file-name $fileName -j";
    $return_code = null;
    $output = null;
    $result = exec($cmd, $output, $return_code);

    return [
        'validated' => $validated,
        'result' => $result
    ];
}

?>

<form method="post" enctype="multipart/form-data">
    <input type="file" name="file">
    <button type="submit">send</button>
</form>

<?php
if (!empty($_FILES['file'])) {
    $file = $_FILES['file']['tmp_name'];
    $fileName = $_FILES['file']['name'];

    $workerResult = worker($file, $fileName);

    echo "file: <pre>";
    var_dump($_FILES);
    echo "</pre>";

    echo "</br>";

    echo "validated: <pre>";
    var_dump($workerResult['validated']);
    echo "</pre>";

    echo "</br>";

    echo "result: <pre>";
    echo var_dump(@json_decode($workerResult['result'], true));
    echo "</pre>";
}
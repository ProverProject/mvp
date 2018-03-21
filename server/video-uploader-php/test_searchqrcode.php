<?php
require('utils.php');
$loadConfig_result = loadConfig();
if (!$loadConfig_result[0]) {
    echo $loadConfig_result[1];
    exit(1);
}

if (@$_GET['TEST_SEARCHQRCODE_PASSWORD'] !== TEST_SEARCHQRCODE_PASSWORD) {
    echo 'please, send GET or configure config.json: TEST_SEARCHQRCODE_PASSWORD';
    exit(1);
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

    $result = exec("searchqrcode $file --orig-file-name $fileName -v 2>&1", $output, $return_code);

    echo "file: <pre>";
    var_dump($_FILES);
    echo "</pre>";

    echo "return_code: <pre>";
    var_dump($return_code);
    echo "</pre>";

    echo "output: <pre>";
    var_dump($output);
    echo "</pre>";

    echo "result: <pre>";
    var_dump($result);
    echo "</pre>";
}
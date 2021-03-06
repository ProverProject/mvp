<?php
require('utils.php');
$loadConfig_result = loadConfig();
if (!$loadConfig_result[0]) {
    echo $loadConfig_result[1];
    exit(1);
}

saveClientInfo('index');
?>

<!DOCTYPE html>

<html lang="en" class="no-js">

<head>
    <meta charset="utf-8">
    <title>Prover video uploader</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <link rel="icon" type="image/x-icon" href="prover-icon-32.png"/>
    <link rel="stylesheet" href="main.css?<?= md5_file('main.css') ?>">
    <link rel="stylesheet" href="//fonts.googleapis.com/css?family=Open+Sans">
    <script type="text/javascript" src="upload.js?<?= md5_file('upload.js') ?>" defer></script>
    <script type="text/javascript" src="send_eth.js?<?= md5_file('send_eth.js') ?>" defer></script>

    <script>
        var r = document.querySelectorAll("html")[0];
        r.className = r.className.replace(/(^|\s)no-js(\s|$)/, "$1js$2")
    </script>
</head>

<body>

<div class="wrapper">
    <label class="switch">
        <input type="checkbox">
        <span class="slider round"></span>
        <p class="switch-prover">Prover</p>
        <p class="switch-clapperboard">Clapperboard</p>
    </label>
    <div id="prover">
        <div class="container">
            <div class="logo">
                <a href="https://prover.io"><img class="logo__img" src="images/logo_bw.svg"></a>
                <!--            <a target="_blank" href="https://play.google.com/store/apps/details?id=io.prover.provermvp"><img class="google__play" src="images/gplay_eng.svg"></a>-->
            </div>
            <!--        <div class="content">-->
            <!---->
            <!--        </div>-->
            <!--        <div class="controllers">-->
            <!--            <a href="manual.html" class="btn">How it works</a>-->
            <!--            <a class="btn" id="get_eth_open">Get ropsten testnet ether</a>-->
            <!--            <br>-->
            <!--            <span id="get_eth_block" style="">-->
            <!--                <input type="search" placeholder="Enter your wallet address" class="btn" id="send_eth_addr"><a href="manual.html" class="btn btn-send" id="send_eth_btn">send 0.05 Eth</a>-->
            <!--            </span>-->
            <!--                <span id="get_eth_loading" class="content" style="display: none;">-->
            <!--                <br>-->
            <!--                <br>-->
            <!--                Loading...-->
            <!--            </span>-->
            <!--                <span id="get_eth_result" class="content" style="display: none;">-->
            <!--                <br>-->
            <!--                <br>-->
            <!--                <span id="get_eth_result_text"></span>-->
            <!--            </span>-->
            <!--        </div>-->
            <!--        <div class="block_client_address_info"></div>-->
            <section id="main" class="main">
                <div class="menu">
                    <ul class="menu-list">
                        <li class="menu-list__item"><a href="#upload-file">Check file</a></li>
                        <li class="menu-list__item"><a href="#get-ether">Get ropsten testnet ether</a></li>
                        <li class="menu-list__item"><a href="#how-it-works">How it works</a></li>
                        <li class="menu-list__item"><a href="#use-cases">Use cases</a></li>
                        <li class="menu-list__item">
                            <a class="market-link" target="_blank" href="https://play.google.com/store/apps/details?id=io.prover.provermvp">
                                <img class="google__play" src="images/googleplay_white.svg">
                            </a>
                        </li>
                    </ul>
                </div>
                <div class="main-image">
                    <img src="images/phone.png" alt="Prover app">
                </div>
                <div class="main-description">
                    <img src="images/icon_prover.svg" alt="Prover icon">
                    <p>
                        Prover is an independent assistant that helps authenticate and verify video content.
                    </p>
                    <p>
                        This online-service was created using blockchain technology.
                        The platform was created to eliminate forgery of video materials, and confirm their authenticity.
                    </p>
                </div>
            </section>
            <section id="upload-file" class="upload-file">
                <form method="post" id="uploadForm" action="file-verify-hash.php" enctype="multipart/form-data" novalidate class="box">
                    <div class="box__input input" onclick="document.getElementById('file').click()">
                        <div class="upload-background"></div>
                        <div class="line line-red"></div>
                        <p class="line-label"></p>
                        <h3 class="box__header">File verification (mp4)</h3>
                        <img class="upload-img" src="images/gear.png">
                        <p class="name-file"></p>
                        <p class="size-file"></p>
                        <div class="success_information">
                            <p class="hash">File hash: <span></span></p>
                            <p class="time_swype-code">Request swype-code on <span></span></p>
                            <p class="time_hash">Submit media hash on <span></span></p>
                            <p class="swype-code">Swype-code: <span></span></p>
                            <p class="swype-begin-end">Swype begin/end: <span></span></p>
                        </div>
                        <div class="error_information">
                            <p class="montage-time">File montage: <span></span></p>
                        </div>
                        <input type="file" name="file" id="file" class="box__file">
                        <a target="_blank" href="" class="download-pdf">Download .pdf certificate</a>
                        <label class="box__labelFile_default" for="">
                            <strong>Choose a file</strong>
                            <span class="box__dragndrop"> or drag it here.</span>
                        </label>
                        <button type="submit" class="box__button">Upload</button>
                    </div>
                </form>
                <p>
                    To authenticate a file, please upload your video. Our system will verify the file hash and existence of
                    swype code. In the case of coincidence of hashes and swype codes - the video file will be considered as
                    authentic.
                </p>
            </section>
            <section id="get-ether" class="get-ether">
                <h3>Get ropsten testnet ether</h3>
                <span id="get_eth_block">
                        <input type="search" placeholder="Enter your wallet address" id="send_eth_addr"><a href="manual.html" class="btn btn-send" id="send_eth_btn">send 0.05 Eth</a>
                    </span>
                <p id="get_eth_result"></p>
            </section>
            <section id="how-it-works" class="how-it-works">
                <h3>How it works</h3>
                <div class="row">
                    <div class="info-block">
                        <div class="img-background">
                            <img class="" src="images/1_pr.svg">
                        </div>
                        <div class="info"><p>Upload a video, recorded with Prover technology.</p></div>
                    </div>
                    <div class="info-block">
                        <div class="img-background">
                            <img class="" src="images/2_pr.svg">
                        </div>
                        <div class="info "><p>Our service will check the hash of a file previously stored in the blockchain and the presence of inputted swype code.</p></div>
                    </div>
                </div>
                <div class="row">
                    <div class="info-block">
                        <div class="img-background">
                            <img class="" src="images/3_pr.svg">
                        </div>
                        <div class="info"><p>In the case of matching hashes, and a swype-code the video file will be considered as authentic.</p></div>
                    </div>
                    <div class="info-block">
                        <div class="img-background">
                            <img class="" src="images/4_pr.svg">
                        </div>
                        <div class="info "><p>You will get the report, with the link of hash of the file and swipe code to be able to verify independently.</p></div>
                    </div>
                </div>
            </section>
            <section id="use-cases" class="use-cases">
                <h3>Use cases</h3>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Both parties involved in a traffic accident can rely on a video recording to prove authenticity of time, date and record of the accident</p>
                </div>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Both users and platforms can prove the authenticity and exclusivity of user-generated video content and share monetization proceeds</p>
                </div>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Doctors and insurance companies can be sure that patients are taking the prescribed drugs properly without keeping them in hospitals</p>
                </div>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Users can be sure that they are chatting with a real person on video dating websites and services</p>
                </div>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Employers and contractors can exchange authentic and time stamped work reports</p>
                </div>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Parties can maintain a Blockchain video database of trusted "hand shake" agreements</p>
                </div>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Public and crowdsourced news platforms can validate the authenticity, exclusivity and timing of video news submitted by individual contributors</p>
                </div>
            </section>
            <section id="faq" class="faq">
                <h3>FAQ</h3>
                <h4><span class="red-line"></span>Where can I get Ropsten Testnet ether?</h4>
                <p>There are many ways to get Ropsten Testnet ether, which you can find out on the Internet. However, we took care of our users and provide our own convenient tool for obtaining a test ether. Just follow <a href="/#get-ether">the link</a>, enter the address of wallet that Prover MVP application generated for you and receive the Ropsten Testnet ether.</p>
                <h4><span class="red-line"></span>Does my video go somewhere when I record it?</h4>
                <p>The files recorded using the Prover MVP application never leave your mobile device. Only the hash of the created video file is sent to the Service and to the blockchain. You can send the video file to our <a href="/">Service</a> to verify its authenticity.</p>
                <h4><span class="red-line"></span>How much does it cost to verify one video?</h4>
                <p>In the demo mode, the payment for video confirmation is performed by the Ropsten Testnet ether, and therefore, it costs nothing. In the final implementation, the user will use service in exchange for the PROOF tokens, while paying the cost of the gas necessary for the performing of Ethereum transactions.</p>
            </section>
            <footer>
                <div class="link mail"><a href="mailto:info@prover.io">info@prover.io</a></div>
                <div class="link social_networks">
                    <a target="_blank" href="https://www.facebook.com/prover.blockchain/"><img src="images/facebook.svg"></a>
                    <a target="_blank" href="https://twitter.com/prover_io"><img src="images/twitter.svg"></a>
                    <a target="_blank" href="https://t.me/joinchat/AAHHrURp4xhK-RuCYhtPlA"><img src="images/telegram.svg"></a>
                </div>
                <div class="link copyright">Prover © 2018</div>
            </footer>
        </div>
    </div>
    <div id="clapperboard" style="display:none; opacity:0">
        <div class="container">
            <div class="logo">
                <a href="https://prover.io"><img class="logo__img" src="images/logo_cp.svg"></a>
                <!--            <a target="_blank" href="https://play.google.com/store/apps/details?id=io.prover.provermvp"><img class="google__play" src="images/gplay_eng.svg"></a>-->
            </div>
            <!--        <div class="content">-->
            <!---->
            <!--        </div>-->
            <!--        <div class="controllers">-->
            <!--            <a href="manual.html" class="btn">How it works</a>-->
            <!--            <a class="btn" id="get_eth_open">Get ropsten testnet ether</a>-->
            <!--            <br>-->
            <!--            <span id="get_eth_block" style="">-->
            <!--                <input type="search" placeholder="Enter your wallet address" class="btn" id="send_eth_addr"><a href="manual.html" class="btn btn-send" id="send_eth_btn">send 0.05 Eth</a>-->
            <!--            </span>-->
            <!--                <span id="get_eth_loading" class="content" style="display: none;">-->
            <!--                <br>-->
            <!--                <br>-->
            <!--                Loading...-->
            <!--            </span>-->
            <!--                <span id="get_eth_result" class="content" style="display: none;">-->
            <!--                <br>-->
            <!--                <br>-->
            <!--                <span id="get_eth_result_text"></span>-->
            <!--            </span>-->
            <!--        </div>-->
            <!--        <div class="block_client_address_info"></div>-->
            <section id="clapperboard-main" class="main">
                <div class="main-description">
                    <img src="images/icon_prover_clapperboard.svg" alt="Prover icon">
                    <p>
                        Blockchain based app for creation of time stamps and the digital signature for fixed  cameras and cameras without internet connection.
                    </p>
                </div>
                <div class="main-image">
                    <img src="images/phone_clapperboard.png" alt="Prover app">
                </div>
                <div class="menu">
                    <ul class="menu-list">
                        <li class="menu-list__item"><a href="#clapperboard-upload-file">Check file</a></li>
                        <li class="menu-list__item"><a href="#clapperboard-get-ether">Get ropsten testnet ether</a></li>
                        <li class="menu-list__item"><a href="#clapperboard-how-it-works">How it works</a></li>
                        <li class="menu-list__item"><a href="#clapperboard-use-cases">Use cases</a></li>
                        <li class="menu-list__item">
                            <a class="market-link" target="_blank" href="https://play.google.com/store/apps/details?id=io.prover.clapperboardmvp">
                                <img class="google__play" src="images/googleplay_black.svg">
                            </a>
                            <a class="market-link" target="_blank" href="https://itunes.apple.com/us/app/prover-clapperboard-mvp/id1362026470?l=ru&ls=1&mt=8">
                                <img class="app__store" src="images/appstore_black.svg">
                            </a>
                        </li>
                    </ul>
                </div>
            </section>
            <section id="clapperboard-upload-file" class="upload-file">
                <form method="post" id="clapperboard-uploadForm" action="file-verify-qr.php" enctype="multipart/form-data" novalidate class="box">
                    <div class="box__input input" onclick="document.getElementById('clapperboard-file').click()">
                        <div class="upload-background"></div>
                        <div class="line line-red"></div>
                        <p class="line-label"></p>
                        <h3 class="box__header">File verification (jpeg, png, mp4)</h3>
                        <img class="upload-img" src="images/gear.png">
                        <p class="name-file"></p>
                        <p class="size-file"></p>
                        <div class="success_information">
                            <p class="hash">File hash: <span></span></p>
                            <p class="date-create">Date create: <span></span></p>
                            <p class="type-text">Type text: <span></span></p>
                        </div>
                        <div class="error_information">
                            <p class="montage-time">File montage: <span></span></p>
                        </div>
                        <input type="file" name="file" id="clapperboard-file" class="box__file">
                        <a target="_blank" href="" class="download-pdf">Download .pdf certificate</a>
                        <label class="box__labelFile_default" for="">
                            <strong>Choose a file</strong>
                            <span class="box__dragndrop"> or drag it here.</span>
                        </label>
                        <button type="submit" class="box__button">Upload</button>
                    </div>
                </form>
                <p>
                    To authenticate a file, please upload your video or image. Our system will verify the file hash and existence of QR code. In the case of coincidence of hashes and QR codes the video file will be considered authentic. QR code must occupy at least 10 % of the uploaded video or image.
                </p>
            </section>
            <section id="clapperboard-get-ether" class="get-ether">
                <h3>Get ropsten testnet ether</h3>
                <span id="get_eth_block">
                            <input type="search" placeholder="Enter your wallet address" id="send_eth_addr"><a href="manual.html" class="btn btn-send" id="send_eth_btn">send 0.05 Eth</a>
                        </span>
                <p id="get_eth_result"></p>
            </section>
            <section id="clapperboard-how-it-works" class="how-it-works">
                <h3>How it works</h3>
                <div class="row">
                    <div class="info-block">
                        <div class="img-background">
                            <img class="" src="images/1_cb.svg">
                        </div>
                        <div class="info"><p>User launches the app and inputs the text information which he wants to be saved in blockchain.</p></div>
                    </div>
                    <div class="info-block">
                        <div class="img-background">
                            <img class="" src="images/2_cb.svg">
                        </div>
                        <div class="info "><p>Then user requests the QR code contains the hash of the transaction and the block at that time, and text information which was previously entered by the user.</p></div>
                    </div>
                </div>
                <div class="row">
                    <div class="info-block">
                        <div class="img-background">
                            <img class="" src="images/3_cb.svg">
                        </div>
                        <div class="info"><p>QR code appears on the screen of an app and user can capture it while filming the video by any kind of digital cameras.</p></div>
                    </div>
                    <div class="info-block">
                        <div class="img-background">
                            <img class="" src="images/4_cb.svg">
                        </div>
                        <div class="info ">
                            <p>
                                User could check the video file with that QR code by uploading it by our app.
                                Video analytics (on a backend) finds and recognizes QR-code, it searches for a block in the blockchain, then retrieves the stored information and detects the block time.
                                If found, — the video is confirmed.
                            </p>
                        </div>
                    </div>
                </div>
            </section>
            <section id="clapperboard-use-cases" class="use-cases">
                <h3>Use cases</h3>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Permanently fixed video cameras (Security, video surveillance, surgery e.t.c)</p>
                </div>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Drones with cameras for video filming and remote inspections</p>
                </div>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Professional digital cameras (for journalism, bloggers, video clips, movies and other professional filming)</p>
                </div>
                <div class="use-case__block">
                    <p><span class="red-line"></span>Cases, when period of recording is too short and does not fit for using SWYPE ID technology (KYC)</p>
                </div>
            </section>
            <footer>
                <div class="link mail"><a href="mailto:info@prover.io">info@prover.io</a></div>
                <div class="link social_networks">
                    <a target="_blank" href="https://www.facebook.com/prover.blockchain/"><img src="images/facebook.svg"></a>
                    <a target="_blank" href="https://twitter.com/prover_io"><img src="images/twitter.svg"></a>
                    <a target="_blank" href="https://t.me/joinchat/AAHHrURp4xhK-RuCYhtPlA"><img src="images/telegram.svg"></a>
                </div>
                <div class="link copyright">Prover © 2018</div>
            </footer>
        </div>
    </div>
</div>

<script type="text/javascript" src="jquery-3.2.1.min.js"></script>
<script type="text/javascript" src="script.js"></script>

</body>

</html>
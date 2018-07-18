// feature detection for drag&drop upload
var isAdvancedUpload = function () {
    var div = document.createElement('div');
    return ( ( 'draggable' in div ) || ( 'ondragstart' in div && 'ondrop' in div ) ) && 'FormData' in window && 'FileReader' in window;
}();

function getSenderInfo(address) {
    var block_clientAddressInfo = document.querySelectorAll('.block_client_address_info')[0];
    block_clientAddressInfo.innerHTML = '';
    var newHtml = '<span>Sender <strong>' + address + '</strong> transactions:</span>';
    var xmlHttp = new XMLHttpRequest();
    xmlHttp.onreadystatechange = function () {
        if (xmlHttp.readyState === 4) {
            if (xmlHttp.status === 200) {
                var result = JSON.parse(xmlHttp.responseText);
                if (result.success) {
                    result.transactions.forEach(function (transaction) {
                        newHtml += '<br>• ' + transaction.blockNumber;
                    });
                } else {
                    newHtml += 'sorry, something goes wrong 😭';
                }
            } else {
                newHtml = 'sorry, something goes wrong 😱😠';
            }
            block_clientAddressInfo.innerHTML = newHtml;
        }
    };
    xmlHttp.open("GET", '/senderInfo.php?senderAddress=' + address, true);
    xmlHttp.send(null);
}

// applying the effect for every form
var forms = document.querySelectorAll('.box');
Array.prototype.forEach.call(forms, function (form) {
    var boxInput, line, labelLine, boxTitle, gearImg, buttonUploadFile, attrOnClick;
    var input = form.querySelector('input[type="file"]'),
        labelFile = form.querySelector('label.box__labelFile_file'),
        labelDefault = form.querySelector('label.box__labelFile_default'),
        successTimeSwypeCode = form.querySelector('.time_swype-code span'),
        successHash = form.querySelector('.hash span'),
        successDateCreateQRCode = form.querySelector('.date-create span'),
        successSwypeCode = form.querySelector('.swype-code span'),
        successTypeText = form.querySelector('.type-text span'),
        errorMontage = form.querySelector('.montage-time span'),
        successDownloadPdf = form.querySelector('.download-pdf'),
        successSwypeBeginEnd = form.querySelector('.swype-begin-end span'),
        successTimeHash = form.querySelector('.time_hash span'),
        restart = form.querySelectorAll('.box__restart'),
        droppedFiles = false,
        triggerFormSubmit = function () {
            var event = document.createEvent('HTMLEvents');
            event.initEvent('submit', true, true);
            form.dispatchEvent(event);
        };

    // letting the server side to know we are going to make an Ajax request
    var ajaxFlag = document.createElement('input');
    ajaxFlag.setAttribute('type', 'hidden');
    ajaxFlag.setAttribute('name', 'ajax');
    ajaxFlag.setAttribute('value', 1);
    form.appendChild(ajaxFlag);

    // automatically submit the form on file select
    input.addEventListener('change', function (e) {
        triggerFormSubmit();
    });

    // drag&drop files if the feature is available
    if (isAdvancedUpload) {
        form.classList.add('has-advanced-upload'); // letting the CSS part to know drag&drop is supported by the browser

        ['drag', 'dragstart', 'dragend', 'dragover', 'dragenter', 'dragleave', 'drop'].forEach(function (event) {
            form.addEventListener(event, function (e) {
                // preventing the unwanted behaviours
                e.preventDefault();
                e.stopPropagation();
            });
        });
        ['dragover', 'dragenter'].forEach(function (event) {
            form.addEventListener(event, function () {
                form.classList.add('is-dragover');
            });
        });
        ['dragleave', 'dragend', 'drop'].forEach(function (event) {
            form.addEventListener(event, function () {
                form.classList.remove('is-dragover');
            });
        });
        form.addEventListener('drop', function (e) {
            form.querySelector('.box__file').files = e.dataTransfer.files;
            triggerFormSubmit();
        });
    }

    function uploadForm(form) {
        var input = form.querySelector('input[type=file]');
        var gearImg = form.querySelector('.upload-img');
        if (input.value) {
            form.querySelector('.box__header').innerHTML = 'Uploading';
            var xhr = new XMLHttpRequest(),
                remind,
                progress = form.querySelector('.progress'),
                uploadBackground = form.querySelector('.upload-background');
            xhr.open('POST', 'index.php');
            xhr.upload.addEventListener('progress', function (e) {
                uploadBackground.style.width = e.loaded / e.total * 100 + '%';
                uploadBackground.style.max = e.total + '%';
                remind = e.loaded / e.total * 100;
                progress.innerHTML = Math.round(remind) + ' %';
                if (remind == 100) {
                    gearImg.classList.add('animating');
                    form.querySelector('.box__header').innerHTML = 'File analysis';
                }
            });
            var formData = new FormData();
            formData.append('file', input.files[0]);
            xhr.send(formData);
        }
    }

    function hexTsToDate(hexTs) {
        return new Date(parseInt(hexTs) * 1000);
    }

    function updateOnResponse(response) {
        console.log(response);
        //todo: remove console.log
        boxInput.classList.remove('error');
        boxInput.classList.remove('success');
        boxInput.classList.remove('uploading');
        if (!response.success) {
            boxInput.classList.add('error');
        } else {
            var msgTimeSwypeCode = 'Nothing found',
                msgTimeHash = 'Nothing found',
                msgHash = 'Nothing found',
                msgTypeText = 'Nothing found',
                msgSwypeCode = 'Nothing found',
                msgDateCreateQRCode = 'Nothing found',
                msgMontage = 'Nothing found',
                msgSwypeBeginEnd = 'Nothing found';

            boxInput.classList.add('success');
            var senderAddressesSpans = '';
            if (response.transactions !== undefined) {
                response.transactions.forEach(function (transaction) {
                    senderAddressesSpans +=
                        '<br>' +
                        '<span' +
                        ' class="box__sender_address"' +
                        ' onclick="getSenderInfo(\'' + transaction.senderAddress + '\')"' +
                        '>' + transaction.senderAddress + '</span>';
                });
                if (response.transactions.length) {
                    if (response.transactions[0].swype) {
                        successSwypeCode.innerHTML = '';
                        msgSwypeCode = response.transactions[0].swype;
                        msgSwypeBeginEnd =
                            response.transactions[0].beginSwypeTime
                            + '/' +
                            response.transactions[0].endSwypeTime;
                    }
                    msgTimeSwypeCode = '';
                    msgTimeHash = '';
                    if (response.debug) {
                        msg = 'Transactions count: ' + response.transactions.length + '.' +
                            (senderAddressesSpans ? ' Sender addresses:' : '') + senderAddressesSpans;
                    } else {
                        var submitMediaHash_ts = response.transactions[0].submitMediaHash_block.timestamp;
                        if (submitMediaHash_ts) {
                            var requestSwypeCode_ts = response.transactions[0].requestSwypeCode_block.timestamp;
                            if (requestSwypeCode_ts) {
                                if (response.transactions[0].transaction2_details.length !== 0)
                                    msgTimeSwypeCode += '<a class="ropsten-link" href="https://ropsten.etherscan.io/tx/'+ response.transactions[0].transaction2_details.transactionHash +'" target="_blank">'+ hexTsToDate(requestSwypeCode_ts) +'</a>';
                                else
                                    msgTimeSwypeCode += '<a class="ropsten-link" href="https://ropsten.etherscan.io/block/'+ parseInt(response.transactions[0].requestSwypeCode_block.number) +'" target="_blank">'+ hexTsToDate(requestSwypeCode_ts) +'</a>';
                            } else {
                                msgTimeSwypeCode += 'not found 😢';
                            }
                            msgTimeHash += '<a class="ropsten-link" href="https://ropsten.etherscan.io/tx/'+ response.transactions[0].transaction1_details.transactionHash +'" target="_blank">'+ hexTsToDate(submitMediaHash_ts) +'</a>';;
                            if (requestSwypeCode_ts) {
                                // msg += '<br>Swype code and relative time later with analytic program';
                            }
                        } else {
                            msgTimeHash += 'can not found submit media hash 😨';
                        }
                    }

                    successTimeSwypeCode.innerHTML = msgTimeSwypeCode;
                    successTimeHash.innerHTML = msgTimeHash;
                    successSwypeCode.innerHTML = msgSwypeCode;
                    successSwypeBeginEnd.innerHTML = msgSwypeBeginEnd;
                }
            }
            if (response.hash)
                msgHash = response.hash;
            successHash.innerHTML = msgHash;
            if (response.cutdetect.length === 0)
                successDownloadPdf.setAttribute('href', response.fileName);

            if (response.datetime_ts) {
                msgDateCreateQRCode = new Date(response.datetime_ts * 1000);
                successDateCreateQRCode.innerHTML = '<a class="ropsten-link" href="https://ropsten.etherscan.io/tx/'+ response.txhash +'" target="_blank">'+ msgDateCreateQRCode +'</a>';
            }

            if (response.typeText) {
                msgTypeText = response.typeText;
                successTypeText.innerHTML = msgTypeText;
            }

            if (response.cutdetect.length !== 0) {
                boxInput.classList.remove('success');
                boxInput.classList.add('montage');
                msgMontage = '';
                response.cutdetect.forEach(function(item, index) {
                    msgMontage += item;
                    if (index != response.cutdetect.length-1)
                        msgMontage += ', ';
                });
                errorMontage.innerHTML = msgMontage;
            }
        }
    }

    // if the form was submitted
    form.addEventListener('submit', function (e) {
        boxInput = form.querySelector('.box__input'),
            line = boxInput.querySelector('.line'),
            labelLine = boxInput.querySelector('.line-label'),
            boxTitle = boxInput.querySelector('.box__header'),
            gearImg = boxInput.querySelector('.upload-img'),
            buttonUploadFile = boxInput.querySelector('.box__labelFile_default strong'),
            attrOnClick = boxInput.getAttribute('onclick');
        if (attrOnClick) {
            boxInput.setAttribute('onclick', '');
            buttonUploadFile.setAttribute('onclick', attrOnClick);
        }

        // preventing the duplicate submissions if the current one is in progress
        if (boxInput.classList.contains('uploading')) {
            return false;
        }

        var inputFile = form.querySelector('.box__file');
        if (inputFile.files.length === 0)
            return false;

        boxInput.classList.remove('success');
        boxInput.classList.remove('montage');
        boxInput.classList.remove('error');
        line.classList.remove('line-green');
        line.classList.add('line-red');

        if (isAdvancedUpload) { // ajax file upload for modern browsers
            e.preventDefault();
            boxInput.classList.remove('input');
            boxInput.querySelector('.name-file').innerHTML = inputFile.files[0].name;
            boxInput.querySelector('.size-file').innerHTML = Number(inputFile.files[0].size / 1048576).toFixed(1) + " Mb";
            boxInput.classList.add('uploading');
            labelLine.classList.add('progress');
            uploadForm(this);

            // gathering the form data
            var ajaxData = new FormData(form);
            if (droppedFiles) {
                Array.prototype.forEach.call(droppedFiles, function (file) {
                    ajaxData.append(input.getAttribute('name'), file);
                });
            }

            // ajax request
            var ajax = new XMLHttpRequest();
            ajax.open(form.getAttribute('method'), form.getAttribute('action'), true);
            ajax.onload = function () {
                if (ajax.status >= 200 && ajax.status < 400) {
                    try {
                        var response = JSON.parse(ajax.responseText);
                        boxInput.classList.remove('uploading');
                        labelLine.classList.remove('progress');
                        gearImg.classList.remove('animating');
                        buttonUploadFile.innerHTML = 'Try another file';
                        line.classList.remove('line-red');
                        line.classList.add(response.success && response.cutdetect.length == 0 ? 'line-green' : 'line-red');
                        boxInput.classList.add(response.success ? response.cutdetect.length == 0 ? 'success' : 'montage' : 'error');
                        boxTitle.innerHTML = response.success && response.cutdetect.length == 0 ? 'Done!' : 'Failed to verify';
                        labelLine.innerHTML = response.success ? response.cutdetect.length == 0 ? 'file hash matched' : 'montage found' : 'nothing found';
                        updateOnResponse(response);
                    } catch (exception) {
                        updateOnResponse({
                            success: false,
                            error: 'upload exception 😱: ' + exception
                        });
                    }
                } else {
                    updateOnResponse({
                        success: false,
                        error: 'upload exception ☹: ' + ajax.status
                    });
                }
            };

            ajax.onerror = function () {
                boxInput.classList.remove('uploading');
                labelLine.classList.remove('progress');
                buttonUploadFile.innerHTML = 'Try another file';
                alert('Error. Please, try again!');
            };

            ajax.send(ajaxData);
        } else { // fallback Ajax solution upload for older browsers
            var iframeName = 'uploadiframe' + new Date().getTime(),
                iframe = document.createElement('iframe');

            var $iframe = $('<iframe name="' + iframeName + '" style="display: none;"></iframe>');

            iframe.setAttribute('name', iframeName);
            iframe.style.display = 'none';

            document.body.appendChild(iframe);
            form.setAttribute('target', iframeName);

            iframe.addEventListener('load', function () {
                var response = JSON.parse(iframe.contentDocument.body.innerHTML);
                form.removeAttribute('target');
                updateOnResponse(response);
                iframe.parentNode.removeChild(iframe);
            });
        }
    });

    // restart the form if has a state of error/success
    Array.prototype.forEach.call(restart, function (entry) {
        entry.addEventListener('click', function (e) {
            e.preventDefault();
            boxInput.classList.remove('error', 'success');
            labelFile.textContent = '';
            labelDefault.style.display = '';
            labelFile.style.display = 'none';
        });
    });

    // Firefox focus bug fix for file input
    input.addEventListener('focus', function () {
        input.classList.add('has-focus');
    });
    input.addEventListener('blur', function () {
        input.classList.remove('has-focus');
    });
});
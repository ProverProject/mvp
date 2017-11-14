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
                console.log(result);
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
    var input = form.querySelector('input[type="file"]'),
        labelFile = form.querySelector('label.box__labelFile_file'),
        labelDefault = form.querySelector('label.box__labelFile_default'),
        successMsg = form.querySelector('.box__success_msg'),
        errorMsg = form.querySelector('.box__error span'),
        restart = form.querySelectorAll('.box__restart'),
        droppedFiles = false,
        showFiles = function (files) {
            labelFile.textContent = files.length > 1 ? ( input.getAttribute('data-multiple-caption') || '' ).replace('{count}', files.length) : files[0].name;
            labelDefault.style.display = 'none';
            labelFile.style.display = '';
        },
        triggerFormSubmit = function () {
            var event = document.createEvent('HTMLEvents');
            event.initEvent('submit', true, false);
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
            droppedFiles = e.dataTransfer.files; // the files that were dropped
            triggerFormSubmit();
        });
    }

    function updateOnResponse(response) {
        if (!response.success) {
            errorMsg.textContent = response.error;
        } else {
            var senderAddressesSpans = '';
            response.transactions.forEach(function (transaction) {
                senderAddressesSpans +=
                    '<br>' +
                    '<span' +
                    ' class="box__sender_address"' +
                    ' onclick="getSenderInfo(\'' + transaction.senderAddress + '\')"' +
                    '>' + transaction.senderAddress + '</span>';
            });
            successMsg.innerHTML =
                'Transactions count: ' + response.transactions.length + '.' +
                (senderAddressesSpans ? ' Sender addresses:' : '') + senderAddressesSpans;
        }
    }

    // if the form was submitted
    form.addEventListener('submit', function (e) {
        // preventing the duplicate submissions if the current one is in progress
        if (form.classList.contains('is-uploading')) {
            return false;
        }

        form.classList.remove('is-error');
        form.classList.remove('is-success');
        form.classList.add('is-uploading');

        if (isAdvancedUpload) { // ajax file upload for modern browsers
            e.preventDefault();

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
                form.classList.remove('is-uploading');
                if (ajax.status >= 200 && ajax.status < 400) {
                    var response = JSON.parse(ajax.responseText);
                    form.classList.add(response.success ? 'is-success' : 'is-error');
                    updateOnResponse(response);
                }
                else {
                    alert('Error. Please, contact the webmaster!');
                }
            };

            ajax.onerror = function () {
                form.classList.remove('is-uploading');
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
                form.classList.remove('is-uploading');
                form.classList.add(response.success ? 'is-success' : 'is-error');
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
            form.classList.remove('is-error', 'is-success');
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
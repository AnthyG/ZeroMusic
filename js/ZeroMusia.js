function loadR(file) {
    player.innerHTML = '<source src="' + file + '" />'
    player.load();
    player.play();

    // $.ajax({
    //     "url": "/186unjYTKeFSPKJW43ZPb5jnDgqtzxCRKf/" + file,
    //     "success": (data) => {
    //         console.log(data)
    //     }
    // });
}

var context = new window.AudioContext();
var source = null;
var audioBuffer = null;

// Converts an ArrayBuffer to base64, by converting to string 
// and then using window.btoa' to base64. 

var bufferToBase64 = function(buffer) {
    var bytes = new Uint8Array(buffer);
    var len = buffer.byteLength;
    var binary = "";
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    return window.btoa(binary);
};

var base64ToBuffer = function(buffer) {
    var binary = window.atob(buffer);
    var buffer = new ArrayBuffer(binary.length);
    var bytes = new Uint8Array(buffer);
    for (var i = 0; i < buffer.byteLength; i++) {
        bytes[i] = binary.charCodeAt(i) & 0xFF;
    }
    return buffer;
};

function stopSound() {
    if (source) {
        source.noteOff(0);
    }
}

function playSound() {
    // source is global so we can call .noteOff() later.
    source = context.createBufferSource();
    source.buffer = audioBuffer;
    source.loop = false;
    source.connect(context.destination);
    source.noteOn(0); // Play immediately.
}

function initSound(arrayBuffer) {
    var base64String = bufferToBase64(arrayBuffer);
    var audioFromString = base64ToBuffer(base64String);
    console.log(base64String);
    context.decodeAudioData(audioFromString, function(buffer) {
        // audioBuffer is global to reuse the decoded audio later.
        audioBuffer = buffer;
        var buttons = document.querySelectorAll('button');
        buttons[0].disabled = false;
        buttons[1].disabled = false;
    }, function(e) {
        console.log('Error decoding file', e);
    });
}

function loadSoundFile(url) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', url, true);
    xhr.responseType = 'arraybuffer';
    xhr.onload = function(e) {
        initSound(this.response); // this.response is an ArrayBuffer.
    };
    xhr.send();
}
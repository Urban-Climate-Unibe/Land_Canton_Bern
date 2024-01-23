window.onload = function() {
    var slider = document.getElementById('slider');
    var photo = document.getElementById('photo');
    var startDate = new Date(); // Get the current date and time
    startDate.setHours(0, 0, 0, 0); // Set to midnight of the current day

    var initialPhotoSrc = calculatePhotoName(0);
    photo.src = initialPhotoSrc;

    slider.addEventListener('input', function(e) {
        var hourOffset = parseInt(e.target.value);
        var photoSrc = calculatePhotoName(hourOffset);
        photo.src = photoSrc;
    });
}

function calculatePhotoName(hourOffset) {
    var startDate = new Date(); // Get the current date and time
    startDate.setHours(0, 0, 0, 0); // Set to midnight of the current day

    // Add the hour offset
    startDate.setHours(startDate.getHours() + hourOffset);

    var year = startDate.getFullYear();
    var month = pad(startDate.getMonth() + 1); // JavaScript months are 0-indexed
    var day = pad(startDate.getDate());
    var hour = pad(startDate.getHours());
    var minute = '00';
    var second = '00';

    // Updated format: year-month-day_hour-minute-second.jpg
    return year + '-' + month + '-' + day + '_' + hour + '-' + minute + '-' + second + '.jpg';
}

function pad(number) {
    if (number < 10) {
        return '0' + number;
    } else {
        return number.toString();
    }
}


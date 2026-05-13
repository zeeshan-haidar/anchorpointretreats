function initScheduleForm(){
    $('#schedule-form').on('submit', function (e) {
        e.preventDefault(); // stop form submit

        // Get field values
        const name  = $('#name').val().trim();
        const email = $('#email').val().trim();
        const date  = $('#date').val().trim();

        // Hide both messages first
        $('.success-message, .error-message').addClass('hidden');

        // Validation check
        if (name !== '' && email !== '' && date !== '') {
            // Show success
            $('.success-message').removeClass('hidden');

            // Hide after 3 seconds
            setTimeout(function() {
                $('.success-message').addClass('hidden');
            }, 3000);

            // Optional: reset form
            // this.reset();
        } else {
            // Show error
            $('.error-message').removeClass('hidden');

            // Hide after 3 seconds
            setTimeout(function() {
                $('.error-message').addClass('hidden');
            }, 3000);
        }
    });
}

function initNewsletterForm(){
    $('#newsletter-form').on('submit', function (e) {
        e.preventDefault(); // stop form submit

        // Get field values
        const newsletter  = $('#newsletter').val().trim();

        // Hide both messages first
        $('.success-message-newsletter, .error-message-newsletter').addClass('hidden');

        // Validation check
        if (newsletter !== '') {
            // Show success
            $('.success-message-newsletter').removeClass('hidden');

            // Hide after 3 seconds
            setTimeout(function() {
                $('.success-message-newsletter').addClass('hidden');
            }, 3000);

            // Optional: reset form
            // this.reset();
        } else {
            // Show error
            $('.error-message-newsletter').removeClass('hidden');

            // Hide after 3 seconds
            setTimeout(function() {
                $('.error-message-newsletter').addClass('hidden');
            }, 3000);
        }
    });
}

$(document).ready(function () {
    initScheduleForm();
    initNewsletterForm();
});
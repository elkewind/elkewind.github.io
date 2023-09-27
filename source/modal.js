// modal.js

// Get the modal and image elements by their IDs
var modal = document.getElementById("imageModal");
var modalImage = document.getElementById("modalImage");
var closeBtn = document.getElementById("closeModal");
var image = document.getElementById("enlargeImage");

// Function to open the modal
image.onclick = function () {
  modal.style.display = "block";
  modalImage.src = this.src; // Set the source of the enlarged image
};

// Function to close the modal
closeBtn.onclick = function () {
  modal.style.display = "none";
};

// Close the modal if the user clicks outside the modal content
window.onclick = function (event) {
  if (event.target == modal) {
    modal.style.display = "none";
  }
};

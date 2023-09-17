const imagePaths = [
  'images/waves2.png',
  'images/leaves.png',
  'images/leaves2.png'
];

let currentImageIndex = 0;

function changeBannerImage() {
  // Get the banner image element
  const bannerImage = document.getElementById('banner-image');

  // Update the image source
  bannerImage.src = imagePaths[currentImageIndex];

  // Increment the current image index
  currentImageIndex = (currentImageIndex + 1) % imagePaths.length;
}

const nextButton = document.getElementById('next-button');
nextButton.addEventListener('click', changeBannerImage);

changeBannerImage();

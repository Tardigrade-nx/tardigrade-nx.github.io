// Les chemins sont relatifs pour fonctionner aussi dans un sous-dossier GitHub Pages.
// albums.js contient la liste des photographies, maintenue manuellement.
const photos = albums.flatMap(album => album.files.map(file => ({
  src: `photos/${encodeURIComponent(album.folder)}/${encodeURIComponent(file)}`, category: album.label, file,
})));
const photoLabel = photos.length > 1 ? 'photographies' : 'photographie';
const familyLabel = albums.length > 1 ? 'familles' : 'famille';
document.querySelector('#collection-count').textContent =
  `${photos.length} ${photoLabel} · ${albums.length} ${familyLabel} d’animaux`;

const grid = document.querySelector('#photos');
const filters = document.querySelector('#filters');
const viewer = document.querySelector('#viewer');
let visible = photos;
let current = 0;
let opener;

function displayPhoto() {
  const photo = visible[current];
  const image = document.querySelector('#full-photo');
  image.src = photo.src;
  image.alt = `${photo.category} — photographie ${photo.file}`;
  document.querySelector('#viewer-title').textContent = `${photo.category} · ${photo.file}`;
  document.querySelector('#position').textContent = `${current + 1} / ${visible.length}`;
}

function render(category) {
  visible = category === 'Toutes' ? photos : photos.filter(photo => photo.category === category);
  grid.replaceChildren();
  visible.forEach((photo, index) => {
    const figure = document.createElement('figure');
    figure.className = 'photo';
    const button = document.createElement('button');
    button.type = 'button';
    button.setAttribute('aria-label', `Agrandir : ${photo.category}, ${photo.file}`);
    const image = document.createElement('img');
    image.src = photo.src;
    image.alt = `${photo.category} — photographie ${photo.file}`;
    image.width = 1280;
    image.height = 960;
    image.loading = 'lazy';
    image.decoding = 'async';
    button.append(image);
    button.addEventListener('click', () => {
      current = index;
      opener = button;
      displayPhoto();
      viewer.showModal();
    });
    const caption = document.createElement('figcaption');
    const label = document.createElement('span');
    label.textContent = photo.category;
    const filename = document.createElement('small');
    filename.textContent = photo.file.replace(/\.jpe?g$/i, '');
    caption.append(label, filename);
    figure.append(button, caption);
    grid.append(figure);
  });
  document.querySelector('#count').textContent = `${visible.length} ${visible.length > 1 ? 'photographies' : 'photographie'}`;
  if (!visible.length) grid.textContent = 'Aucune photographie pour le moment.';
  for (const button of filters.children) {
    button.setAttribute('aria-pressed', String(button.textContent === category));
  }
}

for (const category of ['Toutes', ...albums.map(album => album.label)]) {
  const button = document.createElement('button');
  button.type = 'button';
  button.textContent = category;
  button.addEventListener('click', () => render(category));
  filters.append(button);
}
document.querySelector('#close').addEventListener('click', () => viewer.close());
viewer.addEventListener('close', () => opener?.focus());
viewer.addEventListener('click', event => {
  if (event.target === viewer) {
    const bounds = viewer.getBoundingClientRect();
    if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) viewer.close();
  }
});
function move(delta) {
  current = (current + delta + visible.length) % visible.length;
  displayPhoto();
}
document.querySelector('#previous').addEventListener('click', () => move(-1));
document.querySelector('#next').addEventListener('click', () => move(1));
viewer.addEventListener('keydown', event => {
  if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
    event.preventDefault();
    move(event.key === 'ArrowLeft' ? -1 : 1);
  }
});
render('Toutes');

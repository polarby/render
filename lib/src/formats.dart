
enum MotionFormat {
  mp4,
  mov,

  /// animated GIF
  gif,

  ///APNG, Animated Portable Network Graphics
  apng,
}

enum ImageFormat {
  ///.Y.U.V,	one raw file per component
  yuv,

  ///Alias PIX,	Alias/Wavefront PIX image format
  als,

  ///BMP, Microsoft BMP image
  mpb,

  ///BRender PIX, Argonaut BRender 3D engine image format.
  pix,

  ///CRI, Cintel RAW
  cri,

  /// DPX, Digital Picture Exchange
  dpx,

  /// EXR, OpenEXR
  exr,

  /// FITS, Flexible Image Transport System
  fits,

  /// HDR, Radiance HDR RGBE Image format
  hdr,

  /// IMG, GEM Raster image
  img,

  /// JPEG,
  jpeg,

  /// MSP, Microsoft Paint image
  msp,

  /// PAM, PAM is a PNM extension with alpha support.
  pam,

  /// PBM, Portable BitMap image
  pbm,

  /// PCD, PhotoCD
  pcd,

  /// PCX, PC Paintbrush
  pcx,

  /// PFM, Portable FloatMap image
  pfm,

  /// PGM, Portable GrayMap image
  pgm,

  /// PGMYUV, PGM with U and V components in YUV 4:2:0
  pgmyuv,

  /// PGX, PGX file decoder
  pgx,

  /// PHM, Portable HalfFloatMap image
  phm,

  /// PIC, Pictor/PC Paint
  pic,

  /// PNG, Portable Network Graphics image (supports transparency)
  png,

  /// PPM, Portable PixelMap image
  ppm,

  /// PSD, Photoshop
  psd,

  /// PTX, V.Flash PTX format
  ptx,

  /// QOI, Quite OK Image format
  qoi,

  /// SGI, SGI RGB image format
  sgi,

  /// Sun Rasterfile, Sun RAS image format
  sun,

  /// TIFF
  tiff,

  /// Truevision Targa, Targa (.TGA) image format
  tga,

  /// VBN, Vizrt Binary Image format
  vbn,

  /// WBMP, Wireless Application Protocol Bitmap image format
  wbmp,

  /// WebP, WebP image format, encoding supported through external library libwebp
  webp,

  /// XBM, BitMap image format
  xbm,

  /// XFace, X-Face image format
  xface,

  /// XPM, PixMap image format
  xpm,

  /// XWD, Window Dump image format
  xwd,
}

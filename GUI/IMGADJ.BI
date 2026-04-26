''
' QB64_GJ_LIB
' GRYMMJACK'S IMAGE ADJUSTMENT (GJ_IMGADJ) LIBRARY
'
' USAGE:
'   Insert '$INCLUDE:'path_to_GJ_LIB/IMGADJ/IMGADJ.BI' at the top of file
'   Insert '$INCLUDE:'path_to_GJ_LIB/IMGADJ/IMGADJ.BM' at the bottom of file
'
' This library provides optimized image adjustment algorithms for QB64PE.
' All functions work by creating new image handles - original images are preserved.
' Memory management: You must _FREEIMAGE the returned handles when done.
'
' Features:
' - Core adjustments: Brightness, Contrast, Gamma, Saturation, Hue
' - Effects: Blur, Glow, Film Grain, Vignette, Posterize, Sepia, Invert
' - Utility: Threshold, Desaturate, Levels, Color Balance  
' - Optimized: Uses _MEMIMAGE, lookup tables, and pre-computed noise
' - Clean API: Simple function calls with consistent parameters
'
' @author grymmjack
' @version 1.0
' @description Comprehensive image adjustment library for QB64PE
''

$INCLUDEONCE

''
' IMAGE ADJUSTMENT CONSTANTS
'
CONST GJ_IMGADJ_DESATURATE_AVERAGE   = 0
CONST GJ_IMGADJ_DESATURATE_LUMINANCE = 1
CONST GJ_IMGADJ_THRESHOLD_BINARY     = 0
CONST GJ_IMGADJ_THRESHOLD_INVERTED   = 1

' Pixel Scaler Constants
CONST GJ_IMGADJ_PIXELSCALER_SXBR2 = 0
CONST GJ_IMGADJ_PIXELSCALER_SXBR3 = 1
CONST GJ_IMGADJ_PIXELSCALER_SXBR4 = 2
CONST GJ_IMGADJ_PIXELSCALER_MMPX2 = 3
CONST GJ_IMGADJ_PIXELSCALER_HQ2XA = 4
CONST GJ_IMGADJ_PIXELSCALER_HQ2XB = 5
CONST GJ_IMGADJ_PIXELSCALER_HQ3XA = 6
CONST GJ_IMGADJ_PIXELSCALER_HQ3XB = 7

' Dithering Algorithm Constants
CONST GJ_IMGADJ_DITHER_ORDERED_2X2           = 0
CONST GJ_IMGADJ_DITHER_ORDERED_4X4           = 1
CONST GJ_IMGADJ_DITHER_ORDERED_8X8           = 2
CONST GJ_IMGADJ_DITHER_ORDERED_16X16         = 3
CONST GJ_IMGADJ_DITHER_FLOYD_STEINBERG       = 4
CONST GJ_IMGADJ_DITHER_JARVIS_JUDICE_NINKE   = 5
CONST GJ_IMGADJ_DITHER_STUCKI                = 6
CONST GJ_IMGADJ_DITHER_BURKES                = 7
CONST GJ_IMGADJ_DITHER_SIERRA                = 8
CONST GJ_IMGADJ_DITHER_SIERRA_LITE           = 9
CONST GJ_IMGADJ_DITHER_ATKINSON              = 10
CONST GJ_IMGADJ_DITHER_FALSE_FLOYD_STEINBERG = 11
CONST GJ_IMGADJ_DITHER_FAN                   = 12
CONST GJ_IMGADJ_DITHER_STEVENSON_ARCE        = 13
CONST GJ_IMGADJ_DITHER_TWO_ROW_SIERRA        = 14
CONST GJ_IMGADJ_DITHER_SHIAU_FAN             = 15
CONST GJ_IMGADJ_DITHER_RANDOM                = 16
CONST GJ_IMGADJ_DITHER_BLUE_NOISE            = 17
CONST GJ_IMGADJ_DITHER_CLUSTERED_DOT         = 18
CONST GJ_IMGADJ_DITHER_HALFTONE              = 19
CONST GJ_IMGADJ_DITHER_SPIRAL                = 20
CONST GJ_IMGADJ_DITHER_INTERLEAVED_GRADIENT  = 21

''
' SHARED STATE FOR OPTIMIZATIONS
'

DIM SHARED GJ_IMGADJ_noise(0 TO 65535) AS INTEGER
DIM SHARED GJ_IMGADJ_noiseInit AS INTEGER

' Dithering cache for palette color lookups
DIM SHARED GJ_IMGADJ_dither_cache_valid AS INTEGER

' --- Function Declarations ---

' --- Dithering Functions ---

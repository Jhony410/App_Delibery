Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;

public static class IconGen
{
    static Bitmap Load(string p) { using (var t = new Bitmap(p)) return new Bitmap(t); }

    // El logo es azul/cian sobre blanco, con esquinas negras: solo cuentan como
    // contenido los pixeles con color real, asi el antialias gris del borde
    // redondeado no infla el bbox.
    static bool IsColored(Color c)
    {
        int mx = Math.Max(c.R, Math.Max(c.G, c.B));
        int mn = Math.Min(c.R, Math.Min(c.G, c.B));
        return mx - mn >= 40;
    }

    // Recorta SOLO el simbolo (pin + lineas de velocidad), dejando fuera la
    // palabra "DeliPuno": a tamano de launcher el texto es ilegible.
    //
    // El corte se detecta solo. El logo es "simbolo + espacio + palabra", y ese
    // espacio es una franja de columnas vacias bastante mas ancha que los huecos
    // entre letras (34px vs 9-25px en el icon.png actual). Cortamos en la primera
    // franja vacia que supere minGapRatio del ancho.
    public static Bitmap Symbol(string src, double minGapRatio)
    {
        Bitmap s = Load(src);

        int[] cols = new int[s.Width];
        for (int x = 0; x < s.Width; x++)
            for (int y = 0; y < s.Height; y++)
                if (IsColored(s.GetPixel(x, y))) cols[x]++;

        int first = -1, last = -1;
        for (int x = 0; x < s.Width; x++)
            if (cols[x] > 0) { if (first < 0) first = x; last = x; }

        int minGap = (int)Math.Round(s.Width * minGapRatio);
        int end = last, run = 0;
        for (int x = first; x <= last; x++)
        {
            if (cols[x] == 0) run++;
            else { if (run >= minGap) { end = x - run - 1; break; } run = 0; }
        }

        int minY = s.Height, maxY = -1;
        for (int x = first; x <= end; x++)
            for (int y = 0; y < s.Height; y++)
                if (IsColored(s.GetPixel(x, y)))
                { if (y < minY) minY = y; if (y > maxY) maxY = y; }

        // margen para no cortar el antialias del propio logo
        int pad = 6;
        int minX = Math.Max(0, first - pad), maxX = Math.Min(s.Width - 1, end + pad);
        minY = Math.Max(0, minY - pad); maxY = Math.Min(s.Height - 1, maxY + pad);
        int w = maxX - minX + 1, h = maxY - minY + 1;
        Console.WriteLine("simbolo: x=" + minX + ".." + maxX + " y=" + minY + ".." + maxY + " (" + w + "x" + h + ")");

        // el fondo (blanco y negro) se vuelve transparente; queda el logo suelto
        Bitmap crop = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                Color c = s.GetPixel(minX + x, minY + y);
                int mx = Math.Max(c.R, Math.Max(c.G, c.B));
                int mn = Math.Min(c.R, Math.Min(c.G, c.B));
                if (mx < 40 || mn > 235) crop.SetPixel(x, y, Color.FromArgb(0, 255, 255, 255));
                else crop.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
            }
        s.Dispose();
        return crop;
    }

    static void DrawCentered(Graphics g, Bitmap sym, int size, double scale)
    {
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.SmoothingMode = SmoothingMode.HighQuality;
        double box = size * scale;
        double sc = Math.Min(box / sym.Width, box / sym.Height);
        int dw = (int)Math.Round(sym.Width * sc), dh = (int)Math.Round(sym.Height * sc);
        g.DrawImage(sym, new Rectangle((size - dw) / 2, (size - dh) / 2, dw, dh));
    }

    // iOS / web / Windows: fondo blanco solido, sin alfa (iOS lo exige).
    public static Bitmap Flat(Bitmap sym, int size, double scale)
    {
        Bitmap o = new Bitmap(size, size, PixelFormat.Format24bppRgb);
        using (Graphics g = Graphics.FromImage(o))
        {
            g.Clear(Color.White);
            DrawCentered(g, sym, size, scale);
        }
        return o;
    }

    // Android legacy: cuadrado blanco de esquinas redondeadas sobre transparente.
    public static Bitmap Rounded(Bitmap sym, int size, double scale, double radiusRatio)
    {
        Bitmap o = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(o))
        {
            g.Clear(Color.Transparent);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            int d = (int)Math.Round(size * radiusRatio * 2);
            using (GraphicsPath p = new GraphicsPath())
            {
                p.AddArc(0, 0, d, d, 180, 90);
                p.AddArc(size - d - 1, 0, d, d, 270, 90);
                p.AddArc(size - d - 1, size - d - 1, d, d, 0, 90);
                p.AddArc(0, size - d - 1, d, d, 90, 90);
                p.CloseFigure();
                g.FillPath(Brushes.White, p);
            }
            DrawCentered(g, sym, size, scale);
        }
        return o;
    }

    // Android adaptativo: solo el simbolo sobre transparente; el fondo blanco
    // lo pone adaptive_icon_background.
    public static Bitmap Foreground(Bitmap sym, int size, double scale)
    {
        Bitmap o = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(o))
        {
            g.Clear(Color.Transparent);
            DrawCentered(g, sym, size, scale);
        }
        return o;
    }
}
'@ -ReferencedAssemblies System.Drawing

$dir = $PSScriptRoot
$src = "$dir\icon.png"

# Simbolo recortado, reutilizado por los tres derivados.
$sym = [IconGen]::Symbol($src, 0.02)

# 1) Android legacy: esquinas redondeadas transparentes.
$a = [IconGen]::Rounded($sym, 1024, 0.72, 0.22)
$a.Save("$dir\icon_android.png", [System.Drawing.Imaging.ImageFormat]::Png)
$a.Dispose()

# 2) iOS / web / Windows: sin alfa, fondo blanco de borde a borde.
$f = [IconGen]::Flat($sym, 1024, 0.72)
$f.Save("$dir\icon_ios.png", [System.Drawing.Imaging.ImageFormat]::Png)
$f.Dispose()

# 3) Foreground adaptativo.
# flutter_launcher_icons envuelve el drawable en <inset android:inset="16%">,
# o sea que solo queda el 68% del lienzo. Para que el simbolo termine ocupando
# ~54% del icono de 108dp (=58dp, dentro de la zona segura de 66dp) hay que
# dibujarlo al 0.54/0.68 = 0.79 de este PNG.
$fg = [IconGen]::Foreground($sym, 1024, 0.79)
$fg.Save("$dir\icon_foreground.png", [System.Drawing.Imaging.ImageFormat]::Png)
$fg.Dispose()

$sym.Dispose()

Get-ChildItem $dir -Filter *.png | Select-Object Name, Length

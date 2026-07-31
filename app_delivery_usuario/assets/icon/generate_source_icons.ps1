Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;

public static class IconGen
{
    static Bitmap Load(string p) { using (var t = new Bitmap(p)) return new Bitmap(t); }

    // Devuelve copia 32bpp con: negro de fondo -> transparente (o blanco)
    public static Bitmap Normalize(string src, bool blackToWhite)
    {
        Bitmap s = Load(src);
        Bitmap o = new Bitmap(s.Width, s.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < s.Height; y++)
            for (int x = 0; x < s.Width; x++)
            {
                Color c = s.GetPixel(x, y);
                int max = Math.Max(c.R, Math.Max(c.G, c.B));
                if (max < 40)
                    o.SetPixel(x, y, blackToWhite ? Color.White : Color.FromArgb(0, 255, 255, 255));
                else
                    o.SetPixel(x, y, Color.FromArgb(255, c.R, c.G, c.B));
            }
        s.Dispose();
        return o;
    }

    public static Bitmap Resize(Bitmap src, int size)
    {
        Bitmap o = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(o))
        {
            g.Clear(Color.Transparent);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.DrawImage(src, new Rectangle(0, 0, size, size));
        }
        return o;
    }

    public static Bitmap Flatten(Bitmap src, int size)
    {
        Bitmap o = new Bitmap(size, size, PixelFormat.Format24bppRgb);
        using (Graphics g = Graphics.FromImage(o))
        {
            g.Clear(Color.White);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.DrawImage(src, new Rectangle(0, 0, size, size));
        }
        return o;
    }

    // Foreground adaptativo: recorta el contenido (ni blanco ni negro),
    // vuelve el blanco transparente y lo escala dentro de la zona segura.
    public static Bitmap Foreground(string src, int size, double safe)
    {
        Bitmap s = Load(src);
        int minX = s.Width, minY = s.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < s.Height; y++)
            for (int x = 0; x < s.Width; x++)
            {
                Color c = s.GetPixel(x, y);
                int mx = Math.Max(c.R, Math.Max(c.G, c.B));
                int mn = Math.Min(c.R, Math.Min(c.G, c.B));
                // el logo es azul/cian: solo cuentan los pixeles con color real,
                // asi el antialias gris del borde redondeado no infla el bbox
                if (mx - mn < 40) continue;
                if (x < minX) minX = x; if (x > maxX) maxX = x;
                if (y < minY) minY = y; if (y > maxY) maxY = y;
            }
        // margen para no cortar el antialias del propio logo
        int pad = 6;
        minX = Math.Max(0, minX - pad); minY = Math.Max(0, minY - pad);
        maxX = Math.Min(s.Width - 1, maxX + pad); maxY = Math.Min(s.Height - 1, maxY + pad);
        int w = maxX - minX + 1, h = maxY - minY + 1;
        Console.WriteLine("bbox: x=" + minX + " y=" + minY + " w=" + w + " h=" + h);

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

        double box = size * safe;
        double sc = Math.Min(box / w, box / h);
        int dw = (int)Math.Round(w * sc), dh = (int)Math.Round(h * sc);

        Bitmap o = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(o))
        {
            g.Clear(Color.Transparent);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.DrawImage(crop, new Rectangle((size - dw) / 2, (size - dh) / 2, dw, dh));
        }
        crop.Dispose();
        return o;
    }
}
'@ -ReferencedAssemblies System.Drawing

$dir = "D:\Aplicacion Delibery Puno\app_delivery_usuario\assets\icon"
$src = "$dir\icon.png"

# 1) Android legacy: esquinas transparentes
$n = [IconGen]::Normalize($src, $false)
$a = [IconGen]::Resize($n, 1024)
$a.Save("$dir\icon_android.png", [System.Drawing.Imaging.ImageFormat]::Png)
$a.Dispose(); $n.Dispose()

# 2) iOS / web: sin alfa, esquinas blancas
$n2 = [IconGen]::Normalize($src, $true)
$f = [IconGen]::Flatten($n2, 1024)
$f.Save("$dir\icon_ios.png", [System.Drawing.Imaging.ImageFormat]::Png)
$f.Dispose(); $n2.Dispose()

# 3) Foreground adaptativo.
# flutter_launcher_icons envuelve el drawable en <inset android:inset="16%">,
# o sea que solo queda el 68% del lienzo. Para que el logo termine ocupando
# ~54% del icono de 108dp (=58dp, dentro de la zona segura de 66dp) hay que
# dibujarlo al 0.54/0.68 = 0.79 de este PNG.
$fg = [IconGen]::Foreground($src, 1024, 0.79)
$fg.Save("$dir\icon_foreground.png", [System.Drawing.Imaging.ImageFormat]::Png)
$fg.Dispose()

Get-ChildItem $dir | Select-Object Name, Length

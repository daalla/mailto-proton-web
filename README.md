# Mailto Viewer

App agente de macOS que se pone como manejador de enlaces `mailto:` y, por defecto, abre el redactor web de [Proton Mail](https://mail.proton.me) en Google Chrome **sin mostrar ninguna ventana ni ícono en el Dock**. No toca Mail de Apple ni ninguna cuenta de correo.

## Qué hace

Cuando tocás un `mailto:` en cualquier app (Chrome, Safari, un PDF, Vista Previa, etc.):

- Se arma la URL de Proton y se abre en **Google Chrome** (`com.google.Chrome`). Si Chrome no está instalado, usa el navegador predeterminado.
- La app se cierra al toque: no deja ventana ni proceso colgado.

**Para ver el destinatario, copia, asunto y cuerpo** (la ventana de siempre): mantené **Option (⌥)** mientras tocás el enlace. Desde esa ventana podés copiar los campos o abrir Proton a mano.

Si abrís la app directo (Spotlight, Finder, sin un `mailto:`), aparece una ventana chica con:

- El interruptor **Abrir directo en Proton** (encendido por defecto; se guarda en `UserDefaults`)
- **Restaurar Mail como app predeterminada**

Como corre como agente (`LSUIElement`), no tiene ícono en el Dock ni menú en la barra.

Soporta varios destinatarios, `cc`/`bcc`, acentos (UTF-8) y saltos de línea en el cuerpo.

## Requisitos

- macOS 13 o posterior (probado en macOS 26 Tahoe)
- Command Line Tools de Xcode (`swiftc`) para compilar

## Compilar e instalar

```bash
cd ~/Developer/mailto-viewer
chmod +x build.sh
./build.sh install
```

Eso deja `~/Applications/Mailto Viewer.app`, firmada de forma ad-hoc (sin notarizar).

## Dejarla como app de correo predeterminada

Desde la Terminal:

```bash
"$HOME/Applications/Mailto Viewer.app/Contents/MacOS/MailtoViewer" --set-default
```

macOS puede mostrar un diálogo de confirmación: hay que aceptarlo. Eso no cambia cuentas de Mail; solo dice qué app abre los `mailto:`.

Para comprobarlo:

```bash
"$HOME/Applications/Mailto Viewer.app/Contents/MacOS/MailtoViewer" --query-default
```

Debería imprimir `com.daalla.mailtoviewer`.

## Cómo volver atrás (restaurar Mail)

1. Abrí Mailto Viewer (sin un enlace) y tocá **Restaurar Mail como app predeterminada**.
2. O **Ajustes del Sistema → Escritorio y Dock → App de correo predeterminada** y elegí **Mail**.
3. O desde la Terminal:

```bash
"$HOME/Applications/Mailto Viewer.app/Contents/MacOS/MailtoViewer" --restore-mail
```

Eso vuelve a dejar `com.apple.mail` como manejador de `mailto:`. Después podés borrar la app:

```bash
rm -rf "$HOME/Applications/Mailto Viewer.app"
```

## Abrir en Proton

Usa el mismo formato que registra el cliente web de Proton Mail (`applications/mail/src/app/constants.ts`, `MAILTO_PROTOCOL_HANDLER_PATH`):

```
https://mail.proton.me/inbox/#mailto=%s
```

`%s` es el enlace `mailto:` completo, encodeado como `encodeURIComponent` (igual que hace `navigator.registerProtocolHandler` y la app de escritorio de Proton con `#mailto=${encodeURIComponent(url)}`). Así viajan destinatarios, asunto y cuerpo.

Para ver la URL que se armaría, sin abrir el navegador:

```bash
"$HOME/Applications/Mailto Viewer.app/Contents/MacOS/MailtoViewer" --print-proton 'mailto:ana@example.com?subject=Hola'
```

## Extra

```bash
# Parsear un mailto e imprimir los campos
"$HOME/Applications/Mailto Viewer.app/Contents/MacOS/MailtoViewer" --inspect 'mailto:ana@example.com,beto@example.com?cc=c@example.com&bcc=d@example.com&subject=Prueba%20%C3%B1and%C3%BA&body=Hola%0ASegunda%20l%C3%ADnea'
```

Identificador de la app: `com.daalla.mailtoviewer`.

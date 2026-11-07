# Mailto Viewer

App chiquita de macOS que se pone como manejador de enlaces `mailto:` y te muestra el destinatario, copia, asunto y cuerpo **sin pedirte una cuenta**. Desde ahí podés copiar los campos o abrir el borrador en [Proton Mail web](https://mail.proton.me).

No toca Mail de Apple ni ninguna cuenta de correo.

## Qué hace

Cuando tocás un `mailto:` en cualquier app (Safari, un PDF, Vista Previa, etc.), se abre una ventana con:

- **Para**, **Cc**, **Cco**, **Asunto** y **Cuerpo** (solo lectura, seleccionables)
- Un botón **Copiar** por campo, más **Copiar todo**
- **Abrir en Proton**, que abre el redactor web de Proton Mail con el borrador precargado
- **Cerrar**

Si la abrís sin un enlace, muestra una ventana de ayuda.

Soporta varios destinatarios, `cc`/`bcc`, acentos (UTF-8) y saltos de línea en el cuerpo.

## Requisitos

- macOS 13 o posterior (probada la idea en macOS 26 Tahoe)
- Command Line Tools de Xcode (`swiftc`) para compilar

## Compilar e instalar

```bash
cd ~/Developer/mailto-viewer
chmod +x build.sh
./build.sh install
```

Eso deja `~/Applications/Mailto Viewer.app`, firmada de forma ad-hoc (sin notarizar).

## Dejarla como app de correo predeterminada

Opción A, desde la app: menú **Mailto Viewer → Establecer como app de correo predeterminada**, o el botón de la ventana de ayuda.

Opción B, desde la Terminal:

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

1. **Ajustes del Sistema → Escritorio y Dock → App de correo predeterminada** y elegí **Mail**.
2. O desde el menú de Mailto Viewer: **Restaurar Mail como app predeterminada**.
3. O desde la Terminal:

```bash
"$HOME/Applications/Mailto Viewer.app/Contents/MacOS/MailtoViewer" --restore-mail
```

Eso vuelve a dejar `com.apple.mail` como manejador de `mailto:`. Después podés borrar la app:

```bash
rm -rf "$HOME/Applications/Mailto Viewer.app"
```

## Abrir en Proton

El botón usa el mismo formato que registra el cliente web de Proton Mail (`applications/mail/src/app/constants.ts`, `MAILTO_PROTOCOL_HANDLER_PATH`):

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

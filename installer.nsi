!define APPNAME "Aura Estándar"
!define COMPANYNAME "JP Labs"
!define DESCRIPTION "Punto de venta y gestion"
!define VERSIONMAJOR 1
!define VERSIONMINOR 0
!define VERSIONBUILD 0

Name "${APPNAME}"
OutFile "AuraEstandar_Instalador.exe"
InstallDir "$PROGRAMFILES64\${APPNAME}"

# Icono extraído de la carpeta del proyecto
!define MUI_ICON "windows\runner\resources\app_icon.ico"
!define MUI_UNICON "windows\runner\resources\app_icon.ico"

RequestExecutionLevel admin

!include "MUI2.nsh"

!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "Spanish"

Section "Install"
    SetOutPath "$INSTDIR"
    
    # Copia todos los archivos generados durante la compilación de Flutter
    File /r "build\windows\x64\runner\Release\*.*"

    # Acceso directo apuntando a facturador.exe
    CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\facturador.exe" "" "$INSTDIR\facturador.exe" 0
    
    # Desinstalador
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    # Configuración de registro en Windows
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$INSTDIR\uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$INSTDIR\facturador.exe"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\*.*"
    RMDir /r "$INSTDIR"
    Delete "$DESKTOP\${APPNAME}.lnk"
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
SectionEnd

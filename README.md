# Chocolatey Client Manager

### Requisiti

- Account amministratore di dominio
- Repository locale Chocolatey
- [Script di installazione](https://chocolatey.org/install) Chocolatey
- [PSExec](https://docs.microsoft.com/en-us/sysinternals/downloads/psexec) sulla macchina in cui si esegue `chocoClientManager`
- Client raggiungibili dalla macchina in cui si eseguono gli script
- Client inseriti a dominio


**chocoClientManager.ps1**

Ad ogni avvio vengono richieste credenziali amministratore di dominio e il percorso in cui trovare i file generati da `getComputerListFromOuToFile.ps1`.

Tramite un menù è possibile :

- controllare se Chocolatey è già installato su ogni client
- Installare Chocolatey in ogni client remoto, se non è stato individuato 
- Aggiornare i pacchetti Chocolatey installati in ciascun client
- Installare pacchetti Chocolatey in ciascun client 
  - a partire da un file [`*.config`](https://docs.chocolatey.org/en-us/choco/commands/install#packages.config) necessariamente raggiungibile dal client nel 
  - indicando gli id dei pacchetti separati da spazio  (es. 7zip adobereader)

###### Configurazioni
```Powershell
# percorso completo all'eseguibile psexec
$psExec = "C:\psexec\PSTools\PsExec.exe"

...
# <local-repo> deve contenere l'indirizzo FQDN del repository locale Chocolatey
$cmdChocoInstall = "Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://<local-repo>/install.ps1'))"
```


**getComputerListFromOuToFile.ps1**

Viene fatta una query sull'ActiveDirectory alla ricerca di tutte le `ADOrganizationalUnit` che soddisfano il filtro e proposte all'utente.
In base alla scelta viene esportato un file a partire dalla cartella `sharedFolder` in un percorso pari alla struttura della OU.
Nel file sono contenuti gli ADComputer.

###### Configurazioni

```Powershell
# Impostare un filtro per pulire la query dalle OU non desiderate nell'elenco
Get-ADOrganizationalUnit -Filter 'Name -like "*" -and Name -notlike "OU_*"

....

# Percorso alla cartella locale in cui salvare il risultato, necessariamente condivisa. 
# Verrà usata dal chocoClientManager, eseguito in altra macchina.
$sharedFolder = "C:\shared_choco"

....

# Indicare DC in base alla propria configurazione 
$pattern = $pattern.Replace("DC=example,DC=org", "")

...
```

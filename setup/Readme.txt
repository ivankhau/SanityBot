Astro Sanity Astro_Sanity_Automation

Setup Instructions:
1. Install wgtoken:

->  # If you have not already installed PIP:
    $ easy_install --user --index-url https://pypi.apple.com/simple pip
    Searching for pip
    Reading https://pypi.apple.com/simple/pip/
    …
    Finished processing dependencies for pip
->  $ export PATH=$PATH:$(python -m site --user-base)/bin

->  $ pip install --user --upgrade --index-url https://pypi.apple.com/simple python-wgtoken
    Looking in indexes: https://pypi.apple.com/simple
    Collecting python-wgtoken
    …
    Successfully installed certifi-2018.11.29 chardet-3.0.4 idna-2.8 pyotp-2.2.7 python-wgtoken-1.9 recertifi-0.9.3 requests-2.21.0 requests-toolbelt-0.9.1 urllib3-1.24.1

2. Create a cache.txt and settings.txt in ./splgofer-astrotools/Astro_Sanity_Automation.
3. cache.txt should be empty and for settings.txt, see ./splgofer-astrotools/Astro_Sanity_Automation/setup/settings.txt as a template.
4. Create a sanity.lua sequence and place it in ./splgofer-astrotools/Astro_Sanity_Automation.
5. Run run_sanity.sh in terminal.

Clone a specific folder within my EN525.742 class directory, by performing the following:
    1. Copy Git Clone URL link
    2. Clone Repo into an empty Local Folder: git clone --filter=blob:none --no-checkout <URL.git>
    3. Cd into cloned folder and set Sparse: git sparse-checkout set --cone
    4. Verify that you are on main branch: git checkout main
    5. Clone the specific folder: git sparse-checkout set [path or name]

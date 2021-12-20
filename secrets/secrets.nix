let
  common = [
    "age14qad9xw7a64nf3htem338tmykkx4em753a9y4lus4u63ce4rf4sqngec0a" # root deploy key

    "age1667fd5ewqa9xvyx523d6detesmpufps7llcvjqu63wh8x52yu47qh64v58" # meeksorkim2 2021-12-20
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFwKksjbV5NL8YrzYBhTVEfq0vyk3fSUJClxFKBv94aP" # meeksorkim2 2021-12-20
  ];
in
{
  "passwords/root.age".publicKeys = common ++ [
  ];
  "passwords/mark.age".publicKeys = common ++ [
  ];
}

{ lib, ... }:

let
  defPassword = user: {
    name = "user-password-${user}";
    value = {
      file = ./${user}.age;
      path = "/private/user/default-passwords/${user}";
      symlink = false; # we always want working passwords, even when decryption fails
    };
  };

  defUser = user: {
    name = user;
    value = {
      passwordFile = "/private/user/default-passwords/${user}";
    };
  };

  users = [
    "root"
    "mark"
  ];
in
{
  age.secrets = lib.listToAttrs (map defPassword users);
  users.users = lib.listToAttrs (map defUser users);
}

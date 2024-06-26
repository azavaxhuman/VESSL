# What is VESSL?
VESSL ( Very Easy SSL ) forked from [ESSL](https://github.com/erfjab/ESSL) , in addition to the advantages of the original version, its problems have been resolved and brief but important features have been added to it.

### Future's:
- Single domain ssl (sub.domain.com)
- Wildcard domain ssl (*.domain.com)
- Multi-domain ssl (sub1.doamin1.com sub2.domain2.com)
- Renewal ssl (update)
- Revoke ssl (delete)
- Automatic/Custom patch (support all panel's directory)

### New Future's:
- Add an option to delete packages and certificates
- Moving files in Marzban option bug resolved
- Cloudflare API bug resolved
### Support:
- Acme
- Certbot
- Cloudflare api

> [!IMPORTANT]
> The script automatically tests both acme and certbot to generate the certificate.

## How to Use?

just copy/paste and enjoy : 

```bash
sudo bash -c "$(curl -sL https://github.com/azavaxhuman/ESSL/raw/main/essl.sh)"
```
<details>

<summary>Single Domain</summary>

1. acme & certbot
	In single domain after set DNS you only need :
	- `domain` (e.g: sub.doamin.com)
	- `email`
	
	After receiving ssl, it will show you three path, the first one is for the desired path, the second one is for the border panel path and the third one is for the path of other panels. You received a certificate so easily and easily.
2. cloudflare api
	> Cloudflare api only generates wildcard certificates.

	With cloudflare api you don't need to set dns. well:
	- `domain` (e.g: domain.com)
	- `cloudflare account email`
	- `cloudflare global api key`
	
 	how to find cloudflare global api key : [Link](https://coda.io/@vishesh-jain/api-documentation/cloudflare-global-api-key-15)
	
 	After receiving ssl, it will show you three path, the first one is for the desired path, the second one is for the border panel path and the third one is for the path of other panels. You received a certificate so easily and easily.

</details>


<details>

<summary>Wildcard Domain</summary>

1. acme & certbot

	In wildcard domain after set DNS you only need :
	- `domain` (e.g: domain.com)
	- `email`

	Now it gives you a name and text value, which asks you to set them in text dns format, after a few moments, click set enter.

	After receiving ssl, it will show you three path, the first one is for the desired path, the second one is for the border panel path and the third one is for the path of other panels. You received a certificate so easily and easily.
2. cloudflare api

	> Cloudflare api only generates wildcard certificates.
 
	With cloudflare api you don't need to set dns. well:
	- `domain` (e.g: domain.com)
	- `cloudflare account email`
	- `cloudflare global api key`
	
 	how to find cloudflare global api key : [Link](https://coda.io/@vishesh-jain/api-documentation/cloudflare-global-api-key-15)
	After receiving ssl, it will show you three path, the first one is for the desired path, the second one is for the border panel path and the third one is for the path of other panels. You received a certificate so easily and easily.

</details>


<details>

<summary>Multi-Domain</summary>
	
In Multi domain after set DNS you only need :
- `domain's` (in a line with a space e.g: sub1.domain1.com sub2.domain2.com...)
- `email`

After receiving ssl, it will show you three path, the first one is for the desired path, the second one is for the border panel path and the third one is for the path of other panels. You received a certificate so easily and easily.
</details>

<details>

<summary>Renewal</summary>
	
In renewal you only need :
- `domain` (e.g: *.domain.com (wildcard) sub.domain.com (single))

If it needs to be extended, it will be extended, otherwise it will say that it is not needed yet.
</details>


<details>

<summary>Revoke</summary>
	
In Revoke fi you only need :
- `domain` (e.g: *.domain.com (wildcard) sub.domain.com (single))

If your domain is in the domain list, it will revoked.
</details>

## Thanks
Special thanks to erfjab [(ٍESSL-Github)](https://github.com/erfjab/ESSL)





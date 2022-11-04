Se doreste o implementare care sa permita adunarea de fonduri de la mai multi contribuitori si distribuirea acestora unor beneficiari.

Implementati trei contracte: CrowdFunding, SponsorFunding si DistributeFunding, care sa functioneze in modul descris mai jos:

Contractul CrowdFunding include un o suma tinta - "fundingGoal" - ce se doreste sa fie adunata de la mai multi contribuitori. Un contribuitor poate fi identificat printr-o adresa. Eventuale alte informatii (ex., nume, etc.) pot fi retinute optional prin intermediul unei structuri.
Contractul SponsorFunding are rolul de a adauga unei sume adunate o extra sponsorizare in cuantum de un procent fixat din suma respectiva. Pentru aceasta contractul SponsorFunding necesita o balanta de fonduri proprii, lipsa unei balante suficiente (mai mica decat sponsorizarea calculata procentual), rezultand in anularea sponsorizarii. Pentru asigurarea fondurilor contractul va expune o functie apelabila doar de catre proprietarul contractului ce poate realiza doua actiuni: schimbarea procentului de sponsorizare si alimentarea balantei din fondurile proprietarului. De asemenea contractul poate fi initializat printr-un constructor payable cu o suma ca balanta proprie si cu o valoare implicita pentru procentul de sponsorizare.
Contractul DistributeFunding permite adaugarea unui numar de actionari/beneficiari cu rolul de a distribui acestora suma cumulata in final. Fiecare actionar adaugat are o pondere asociata din procentul de 100% al sumei (ponderea totala a actionarilor poate fi mai mica de 100%).

Consideram trei "stari" ale finantarii: 1) "nefinantat" - inainte de atingerea sumei tinta, 2) "prefinantat" - dupa atingerea sumei inainte de sponsorizare, 3) "finantat" - dupa eventuala sponsorizare.
Este posibila interograrea acestei stari (ex., cu un raspuns de tip string mentinut de contractul CrowdFunding) la orice moment de catre oricine pentru a sti in ce stare se afla finantarea.

Inainte de atingerea sumei tinta (starea "nefinantat"), contractul CrowdFunding trebuie sa ofere posibilitatea de:

Depunere a unei sume de catre un contribuitor. La fiecare depunere contractul va verifica daca s-a atins suma tinta.
Retragere a oricarei sume, inclusiv partiala, depuse de un contribuitor.

Dupa atingerea sumei tinta (starea "prefinantat"):

Nu se mai pot retrage sau depune sume.
Proprietarul contractului CrowdFunding poate comunica contractului SponsorFunding finalizarea colectarii sumei, la care contractul SponsorFunding va verifica balanta contractului CrowdFunding si va vira catre acesta sponsorizarea oferita. In cazul in care contractul SponsorFunding nu dispune de o balanta suficienta pentru sponsorizare nu va vira nimic.

Dupa eventuala sponsorizare (starea "finantat"):

Proprietarul contractului CrowdFunding poate vira suma totala adunata catre contractul DistributeFunding.
Doar dupa acest virament, contractul DistributeFunding va permite fiecarui actionar sa isi retraga, o singura data, venitul calculat conform cu ponderea proprie.

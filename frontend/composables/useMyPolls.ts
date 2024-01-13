export default function () {
  const { myPolls } = useQueryOptionsFactory();
  const query = useQuery(myPolls);

  return { query };
}
